import io
import os
import base64
import pickle
from google import genai
from google.genai import types
from PIL import Image
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel

from dotenv import load_dotenv
# 1. Setup the Client
# Ensure your GEMINI_API_KEY is set in your environment variables
app = FastAPI()
load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

class ImageRequest(BaseModel):
    base64Image: str
    style: str

@app.post("/transform")
async def transform_image(request: ImageRequest):
   # 1. Read the image sent from Flutter
    try:
        image_bytes = base64.b64decode(request.base64Image)
    except Exception:
        return {"error": "Invalid base64 string"}
    
    # 2. Define the 'System Instruction' to lock the identity
    system_instruction = (
        "You are a professional Bollywood cinematic artist. "
        "Your goal is to modify the user's appearance into a movie character "
        "while keeping their original eyes, nose, and basic face shape 100% recognizable. "
        "Do not change the person's identity."
    )

    # 3. Create the prompt for the 'Rocky' style
    rocky_prompt = (
        "Apply the 'Rocky Bhai' look from KGF: "
        "1. Add a very thick, dark, groomed full beard that covers the jawline and neck. "
        "2. Change hair to be long, wavy, and shoulder-length. "
        "3. Dress them in a rugged, dusty brown leather jacket. "
        "4. Background: An industrial mining site with dramatic, warm sunset lighting."
    )



    # 5. Call Gemini 3.1 Flash (Nano Banana 2)
    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            # Tell the model we want an image back
            response_modalities=["IMAGE"], 
        ),
        contents=[
            rocky_prompt,
            types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
        ]
    )
    part = response.candidates[0].content.parts[0]

    if part.inline_data:
        image_data = part.inline_data.data
        # If it's already a string, just return it
        if isinstance(image_data, str):
            return {"image": image_data}
        # If it's bytes, encode it first
        return {"image": base64.b64encode(image_data).decode('utf-8')}
#
#     # 6. Save the resulting image
#     for part in response.candidates[0].content.parts:
#         if part.inline_data:
#             #print(f"Success! Saved to {output_path}")
#             return {"image": part.inline_data.data}
