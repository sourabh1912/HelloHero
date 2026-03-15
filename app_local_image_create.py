import io
import os
import base64
import pickle
from google import genai
from google.genai import types
from PIL import Image


# 1. Setup the Client
# Ensure your GEMINI_API_KEY is set in your environment variables
client = genai.Client(api_key="AIzaSyB0mU9hsdipJRdtOduVYgHAjVAQddgkxos")

def transform_to_rocky(image_path, output_path="rocky_result.jpg"):
    """
    Transforms a user photo into the 'Rocky' character from KGF.
    """
    
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

    # 4. Load the user's image
    with open(image_path, "rb") as f:
        image_bytes = f.read()

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

    # 6. Save the resulting image
    for part in response.candidates[0].content.parts:
        if part.inline_data:
            img = Image.open(io.BytesIO(part.inline_data.data))
            img.save(output_path, "JPEG")
            print(f"Success! Saved to {output_path}")

# Run the transformation
if __name__ == "__main__":
    transform_to_rocky("Profile__Sourabh.jpeg")