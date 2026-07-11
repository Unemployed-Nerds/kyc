from typing import Any, Dict
import asyncio
import random
import os
import json
from PIL import Image, ImageDraw

try:
    from google import genai
    from google.genai import types
    has_genai = True
except ImportError:
    has_genai = False

from app.agents.base import BaseAgent

class DocumentAgent(BaseAgent):
    def __init__(self):
        super().__init__("DocumentAgent")
        self.client = genai.Client() if has_genai and os.environ.get("GEMINI_API_KEY") else None

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Verifies document quality using Gemini Vision, or falls back to mock."""
        doc_path = task_data.get("context", {}).get("files", {}).get("document_path")
        
        if self.client and doc_path and os.path.exists(doc_path):
            try:
                myfile = await self.client.aio.files.upload(file=doc_path)
                response = await self.client.aio.models.generate_content(
                    model='nano-banana-pro-preview',
                    contents=[myfile, "Analyze this image. Is it a valid ID document? Is it clear and readable? If it is NOT a valid ID document (e.g. a random picture), or if it is blurry/obscured, reply with REJECTED and provide a bounding box of the non-ID object or blurry region as [ymin, xmin, ymax, xmax] scaled 0-1000. Reply with ONLY JSON: {\"status\": \"APPROVED\" or \"REJECTED\", \"reason\": \"<reason>\", \"quality_score\": <0.0-1.0>, \"box_2d\": [ymin, xmin, ymax, xmax]} (omit box_2d if approved)"]
                )
                cleaned = response.text.replace('```json', '').replace('```', '').strip()
                result = json.loads(cleaned)
                
                # Draw bounding box if present
                if result.get("status") == "REJECTED" and "box_2d" in result:
                    box = result["box_2d"]
                    if isinstance(box, list) and len(box) == 4:
                        try:
                            with Image.open(doc_path) as img:
                                draw = ImageDraw.Draw(img)
                                w, h = img.size
                                ymin, xmin, ymax, xmax = box
                                top = (ymin / 1000) * h
                                left = (xmin / 1000) * w
                                bottom = (ymax / 1000) * h
                                right = (xmax / 1000) * w
                                draw.rectangle(((left, top), (right, bottom)), outline="red", width=5)
                                
                                dir_name = os.path.dirname(doc_path)
                                base_name = os.path.basename(doc_path)
                                annotated_path = os.path.join(dir_name, "annotated_" + base_name)
                                img.save(annotated_path)
                                result["annotated_document_path"] = annotated_path
                        except Exception as e:
                            print(f"Error drawing bounding box: {e}")
                
                return result
            except Exception as e:
                print(f"Gemini error in DocumentAgent: {e}")
                return {"status": "REJECTED", "reason": f"Failed to analyze document: {e}", "quality_score": 0.0}

        # Fallback to mock
        await asyncio.sleep(1) # Simulate processing time
        return {"status": "APPROVED", "quality_score": round(random.uniform(0.8, 1.0), 2)}

class OCRAgent(BaseAgent):
    def __init__(self):
        super().__init__("OCRAgent")
        self.client = genai.Client() if has_genai and os.environ.get("GEMINI_API_KEY") else None

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extracts data using Gemini Vision, or falls back to mock."""
        doc_path = task_data.get("context", {}).get("files", {}).get("document_path")
        
        if self.client and doc_path and os.path.exists(doc_path):
            try:
                myfile = await self.client.aio.files.upload(file=doc_path)
                response = await self.client.aio.models.generate_content(
                    model='gemini-3.5-flash',
                    contents=[myfile, "Extract the following from this ID: first_name, last_name, dob (YYYY-MM-DD), document_number. If the image is not a valid ID, return empty strings. Reply with ONLY JSON: {\"extracted_data\": {\"first_name\": \"...\", \"last_name\": \"...\", \"dob\": \"...\", \"document_number\": \"...\"}, \"confidence\": <0.0-1.0>}"]
                )
                cleaned = response.text.replace('```json', '').replace('```', '').strip()
                return json.loads(cleaned)
            except Exception as e:
                print(f"Gemini error in OCRAgent: {e}")
                return {
                    "extracted_data": {
                        "first_name": "",
                        "last_name": "",
                        "dob": "",
                        "document_number": ""
                    },
                    "confidence": 0.0
                }

        # Fallback to mock: Return the submitted payload to simulate perfect OCR extraction
        # This makes it easy to test clean vs poisoned applications
        await asyncio.sleep(2)
        payload = task_data.get("context", {}).get("customer_data", {})
        return {
            "extracted_data": {
                "first_name": payload.get("first_name", "John"),
                "last_name": payload.get("last_name", "Doe"),
                "dob": payload.get("dob", "1990-01-01"),
                "document_number": f"DOC{random.randint(10000, 99999)}"
            },
            "confidence": round(random.uniform(0.9, 1.0), 2)
        }

class ValidationAgent(BaseAgent):
    def __init__(self):
        super().__init__("ValidationAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Compares extracted OCR data vs user input using fuzzy matching."""
        from thefuzz import fuzz
        
        context = task_data.get("context", {})
        payload = context.get("customer_data", {})
        
        user_input = {
            "first_name": payload.get("first_name", ""),
            "last_name": payload.get("last_name", ""),
            "dob": payload.get("dob", "")
        }
        
        ocr_result = context.get("OCRAgent", {}).get("extracted_data", {})
        
        discrepancies = []
        
        for field in ["first_name", "last_name"]:
            user_val = str(user_input.get(field, "")).strip().lower()
            ocr_val = str(ocr_result.get(field, "")).strip().lower()
            
            # Skip validation if user left it blank (e.g. no last name)
            if not user_val and field == "last_name":
                continue
                
            similarity = fuzz.ratio(user_val, ocr_val)
            if similarity < 85: # Require 85% match for names
                discrepancies.append({
                    "field": field,
                    "user_input": user_val,
                    "ocr_extracted": ocr_val,
                    "similarity": similarity
                })
                
        # Exact match for DOB
        user_dob = str(user_input.get("dob", "")).strip()
        ocr_dob = str(ocr_result.get("dob", "")).strip()
        if user_dob != ocr_dob:
            discrepancies.append({
                "field": "dob",
                "user_input": user_dob,
                "ocr_extracted": ocr_dob,
                "similarity": 0 if user_dob != ocr_dob else 100
            })

        status = "MATCH" if len(discrepancies) == 0 else "MISMATCH"
        
        return {
            "status": status,
            "discrepancies": discrepancies
        }

class SelfieAgent(BaseAgent):
    def __init__(self):
        super().__init__("SelfieAgent")
        self.client = genai.Client() if has_genai and os.environ.get("GEMINI_API_KEY") else None

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Verifies if a single face is present in the selfie using Gemini Vision."""
        selfie_path = task_data.get("context", {}).get("files", {}).get("selfie_path")
        
        if self.client and selfie_path and os.path.exists(selfie_path):
            try:
                myfile = await self.client.aio.files.upload(file=selfie_path)
                response = await self.client.aio.models.generate_content(
                    model='gemini-3.5-flash',
                    contents=[myfile, "Analyze this selfie. Is there a clear, single human face visible? Reply with ONLY JSON: {\"status\": \"APPROVED\" or \"REJECTED\", \"reason\": \"<reason>\"}"]
                )
                cleaned = response.text.replace('```json', '').replace('```', '').strip()
                return json.loads(cleaned)
            except Exception as e:
                print(f"Gemini error in SelfieAgent: {e}")
                return {"status": "REJECTED", "reason": f"Failed to analyze selfie: {e}"}

        # Fallback to mock
        await asyncio.sleep(1)
        return {"status": "APPROVED", "reason": "Mock approved."}

class FaceMatchAgent(BaseAgent):
    def __init__(self):
        super().__init__("FaceMatchAgent")
        self.client = genai.Client() if has_genai and os.environ.get("GEMINI_API_KEY") else None

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Compares the selfie face against the ID document face."""
        doc_path = task_data.get("context", {}).get("files", {}).get("document_path")
        selfie_path = task_data.get("context", {}).get("files", {}).get("selfie_path")
        
        if self.client and doc_path and selfie_path and os.path.exists(doc_path) and os.path.exists(selfie_path):
            try:
                doc_file = await self.client.aio.files.upload(file=doc_path)
                selfie_file = await self.client.aio.files.upload(file=selfie_path)
                
                response = await self.client.aio.models.generate_content(
                    model='gemini-3.5-flash',
                    contents=[
                        doc_file, 
                        selfie_file, 
                        "Compare the face in the ID document (first image) with the face in the selfie (second image). Do they belong to the exact same person? Reply with ONLY JSON: {\"status\": \"MATCH\" or \"MISMATCH\", \"confidence\": <0.0-1.0>, \"reason\": \"<reason>\"}"
                    ]
                )
                cleaned = response.text.replace('```json', '').replace('```', '').strip()
                return json.loads(cleaned)
            except Exception as e:
                print(f"Gemini error in FaceMatchAgent: {e}")
                return {"status": "MISMATCH", "confidence": 0.0, "reason": f"Failed to perform face match: {e}"}

        await asyncio.sleep(1)
        return {"status": "MATCH", "confidence": 0.9, "reason": "Mock matched."}
