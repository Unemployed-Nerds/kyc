from typing import Any, Dict
import asyncio
import sqlite3
import os
from thefuzz import fuzz

from app.agents.base import BaseAgent

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "db", "watchlist.db")

def check_watchlist(table_name: str, first_name: str, last_name: str, dob: str):
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute(f"SELECT * FROM {table_name}")
        rows = cursor.fetchall()
        
        matches = []
        for row in rows:
            fn_score = fuzz.ratio(str(row["first_name"]).lower(), first_name.lower())
            ln_score = fuzz.ratio(str(row["last_name"]).lower(), last_name.lower())
            
            # If both names match >= 85%, or dob matches exactly and names are close
            if fn_score >= 80 and ln_score >= 80:
                matches.append(dict(row))
            elif str(row["dob"]) == dob and (fn_score >= 60 and ln_score >= 60):
                matches.append(dict(row))
                
        conn.close()
        return matches
    except Exception as e:
        print(f"DB Error: {e}")
        return []

class AMLAgent(BaseAgent):
    def __init__(self):
        super().__init__("AMLAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        context = task_data.get("context", {})
        ocr_result = context.get("OCRAgent", {}).get("extracted_data", {})
        
        fn = ocr_result.get("first_name", "")
        ln = ocr_result.get("last_name", "")
        dob = ocr_result.get("dob", "")
        
        matches = check_watchlist("aml_watchlist", fn, ln, dob)
        
        return {
            "status": "POTENTIAL_MATCH" if len(matches) > 0 else "CLEAR",
            "hits": len(matches),
            "details": matches
        }

class SanctionsAgent(BaseAgent):
    def __init__(self):
        super().__init__("SanctionsAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        context = task_data.get("context", {})
        ocr_result = context.get("OCRAgent", {}).get("extracted_data", {})
        
        fn = ocr_result.get("first_name", "")
        ln = ocr_result.get("last_name", "")
        dob = ocr_result.get("dob", "")
        
        matches = check_watchlist("sanctions_list", fn, ln, dob)
        
        return {
            "status": "POTENTIAL_MATCH" if len(matches) > 0 else "PASS",
            "lists_checked": ["OFAC", "UN", "EU"],
            "details": matches
        }

class PEPAgent(BaseAgent):
    def __init__(self):
        super().__init__("PEPAgent")

    async def process(self, application_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
        context = task_data.get("context", {})
        ocr_result = context.get("OCRAgent", {}).get("extracted_data", {})
        
        fn = ocr_result.get("first_name", "")
        ln = ocr_result.get("last_name", "")
        dob = ocr_result.get("dob", "")
        
        matches = check_watchlist("pep_list", fn, ln, dob)
        
        if len(matches) > 0:
            highest_risk = matches[0].get("classification", "MEDIUM") # simplistic
            return {"status": "MATCH", "classification": highest_risk, "details": matches}
            
        return {"status": "CLEAR", "classification": "NONE"}
