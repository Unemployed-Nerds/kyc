import asyncio
from google import genai
import os

async def main():
    client = genai.Client()
    response = await client.aio.models.generate_content(
        model='nano-banana-pro-preview',
        contents=["Hello"]
    )
    print(response.text)

if __name__ == "__main__":
    asyncio.run(main())
