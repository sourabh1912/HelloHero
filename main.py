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

    # 3. Create prompts for different styles
    rocky_prompt = (
        "Apply the 'Rocky Bhai' look from KGF: "
        "1. Add a very thick, dark, groomed full beard that covers the jawline and neck. "
        "2. Change hair to be long, wavy, and shoulder-length. "
        "3. Dress them in a rugged, dusty brown leather jacket. "
        "4. Background: An industrial mining site with dramatic, warm sunset lighting."
    )

    halogen_prompt = (
        "Create a high-fashion halogen-lit studio portrait: "
        "1. Style the subject with sharp, modern features and clean grooming. "
        "2. Use dramatic halogen lighting with strong contrast and soft falloff. "
        "3. Outfit: sleek, minimal, contemporary clothing in dark tones. "
        "4. Background: moody studio with colored halogen accents and cinematic depth."
    )

    gym_prompt = (
            "Generate a powerful gym portrait of a young Indian man with an athletic physique:"
            "1. Wearing a sleeveless black workout tank top and training gloves."
            "2. He is standing inside a modern gym with workout equipment and dim dramatic lighting in the background."
            "3. His expression is focused and confident, with sweat highlights on the skin to add realism. The lighting creates strong shadows that emphasize muscle definition and body shape."
            "4. Include gym mirrors reflecting subtle light and a cinematic fitness environment."
            "5. Ultra-realistic skin texture, sharp jawline, professional fitness photography style, intense atmosphere, shallow depth of field, and ultra-detailed 8K portrait."
    )

    mafia_prompt = (
                "Close-up portrait of a young Indian man with a serious and powerful expression, wearing a sharp black luxury suit with a crisp white shirt and dark tie. His hairstyle is slicked back with subtle stubble on his face, giving a confident mafia-style look. The lighting is low-key and dramatic, creating deep shadows across the face for a cinematic mood. He is sitting in a vintage luxury office chair with a wooden desk and classic decor in the background. A cigar is held casually in his hand (unlit) to enhance the mafia boss aesthetic. Ultra-realistic skin texture, intense eye contact, cinematic 8K detail, dark brown and black color grading, editorial photography style with powerful presence."
    )

    golden_hour_prompt = (
                "An ultra-detailed 8K cinematic portrait. Subject is dramatically backlit by a vibrant golden hour sunset. Warm, glowing halo effect around the hair, deep, soft shadows on the face, shallow depth of field (bokeh), Kodak Portra 400 film emulation, soft lens flare."
    )

    retro_look_prompt = (
                "A classic 1940s studio portrait. Subject is elegantly posed against a dark velvet backdrop. Use Rembrandt lighting (butterfly shadow) for dramatic facial highlights. Sepia color tone, subtle vintage film scratches, high-fashion editorial quality"
    )

    rainy_window_prompt = (
                "A contemplative portrait shot through a rain-streaked window. Subject is illuminated by warm, soft indoor light. Blurred city lights outside creating colorful bokeh. Moody, reflective atmosphere, with a cool blue film filter applied"
    )



    # 4. Choose prompt based on requested style
    if request.style == "halogen_sample":
        chosen_prompt = halogen_prompt
    elif request.style == "rocky_bhai":
        chosen_prompt = rocky_prompt
    elif request.style == "gym_sample":
            chosen_prompt = gym_prompt
    elif request.style == "retro_style":
            chosen_prompt = retro_look_prompt
    elif request.style == "mafia_boss":
            chosen_prompt = mafia_prompt
    elif request.style == "rainy_window":
            chosen_prompt = rainy_window_prompt
    else :
        # Default / fallback to Rocky Bhai
        chosen_prompt = rocky_prompt



    # 5. Call Gemini 3.1 Flash (Nano Banana 2)
    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            # Tell the model we want an image back
            response_modalities=["IMAGE"], 
        ),
        contents=[
            chosen_prompt,
            types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
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
