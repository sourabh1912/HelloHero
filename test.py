import pickle
import base64
from PIL import Image
import io


with open("gemini_response_candidates.pkl", "rb") as f:
    data = pickle.load(f)

candidates = data["candidates"]
image_data = (candidates[0].content.parts[0].inline_data.data)

img = Image.open(io.BytesIO(image_data))
img.save("output.jpg", "JPEG")
# print(img_data)