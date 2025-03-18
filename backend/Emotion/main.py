from fastapi import FastAPI, HTTPException, Depends,File, UploadFile
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator, EmailStr
import pandas as pd
from typing import Optional, Dict, Any
import uvicorn
from datetime import datetime
import io
import numpy as np
from notification_service.email_sender import send_email
from Emotion_via_cam.model import FacialExpressionModel
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
import re
import pickle
import nltk
nltk.download('stopwords')
nltk.download('wordnet')
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
import cv2

# Import the database connection
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from db_connection import auth, db, get_user_by_token, authenticate_user, create_new_user, get_user_profile

app = FastAPI(
    title="Heart Risk Prediction API",
    description="API for predicting heart risk based on patient data"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Pydantic Models
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    emergency_contact: Dict[str, str]

class UserLogin(BaseModel):
    email: EmailStr
    password: str


# Helper Functions
async def get_current_user(token: str = Depends(oauth2_scheme)):
    return get_user_by_token(token)

def create_user_profile(user_id: str, user_data: Dict[str, Any]):
    """Create initial user profile in Firebase Realtime Database"""
    profile_data = {
        "profile": {
            "name": user_data["name"],
            "email": user_data["email"],
        },
        "emergency_contact": user_data["emergency_contact"]
    }
    db.child("users").child(user_id).set(profile_data)
    return profile_data

# API Endpoints
@app.post("/register")
async def register(user_data: UserRegister):
    try:
        # Create user in Firebase Authentication
        user = create_new_user(
            email=user_data.email,
            password=user_data.password
        )
        
        # Create user profile in Realtime Database
        profile = create_user_profile(user['localId'], user_data.dict())
        
        return {
            "message": "Registration successful",
            "user_id": user['localId'],
            "profile": profile
        }
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )

@app.post("/login")
async def login(user_data: UserLogin):
    try:
        # Sign in user with Firebase Authentication
        user = authenticate_user(
            email=user_data.email,
            password=user_data.password
        )
        
        # Get user profile from Realtime Database
        profile = get_user_profile(user['localId'])
        
        return {
            "access_token": user['idToken'],
            "token_type": "bearer",
            "user_id": user['localId'],
            "profile": profile
        }
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )

# Initialize required objects
textModel = load_model('Emotion_via_text/Emotion_Recognition_2.h5')
lemmatizer = WordNetLemmatizer()
stop_words = set(stopwords.words('english'))

# Load face detection model
facec = cv2.CascadeClassifier('Emotion_via_cam/haarcascade_frontalface_default.xml')
faceModel = FacialExpressionModel("Emotion_via_cam/model.json", "Emotion_via_cam/model_weights.h5")
font = cv2.FONT_HERSHEY_SIMPLEX



# Load tokenizer and label encoder
with open('Emotion_via_text/tokenizer_2.pkl', 'rb') as f:
    tokenizer = pickle.load(f)
    
with open('Emotion_via_text/label_encoder_2.pkl', 'rb') as f:
    le = pickle.load(f)

# Input model
class SentenceInput(BaseModel):
    sentence: str

# Text preprocessing functions
def lower_case(text):
    text = text.split()
    text = [y.lower() for y in text]
    return " ".join(text)

def remove_stop_words(text):
    Text = [i for i in str(text).split() if i not in stop_words]
    return " ".join(Text)

def Removing_numbers(text):
    text = ''.join([i for i in text if not i.isdigit()])
    return text

def Removing_punctuations(text):
    text = re.sub('[%s]' % re.escape("""!"#$%&'()*+,،-./:;<=>؟?@[\]^_`{|}~"""), ' ', text)
    text = text.replace('؛', "")
    text = re.sub('\s+', ' ', text)
    text = " ".join(text.split())
    return text.strip()

def Removing_urls(text):
    url_pattern = re.compile(r'https?://\S+|www\.\S+')
    return url_pattern.sub(r'', text)

def lemmatization(text):
    text = text.split()
    text = [lemmatizer.lemmatize(y) for y in text]
    return " ".join(text)

def normalized_sentence(sentence):
    sentence = lower_case(sentence)
    sentence = remove_stop_words(sentence)
    sentence = Removing_numbers(sentence)
    sentence = Removing_punctuations(sentence)
    sentence = Removing_urls(sentence)
    sentence = lemmatization(sentence)
    return sentence

@app.post("/predictEmotion")
async def predict_emotion(input_data: SentenceInput):
    # Preprocess the input sentence
    sentence = normalized_sentence(input_data.sentence)
    
    # Convert to sequence and pad
    sentence = tokenizer.texts_to_sequences([sentence])
    sentence = pad_sequences(sentence, maxlen=229, truncating='pre')
    
    # Make prediction
    prediction = textModel.predict(sentence)
    result = le.inverse_transform(np.argmax(prediction, axis=-1))[0]
    probability = float(np.max(prediction))  # Convert to float for JSON serialization
    
    return {
        "emotion": result,
        "probability": probability
    }

@app.post("/predict-emotion-image")
async def predict_emotion_image(file: UploadFile = File(...)) -> Dict:
    try:
        # Save uploaded file temporarily
        temp_file_path = f"temp_{file.filename}"
        with open(temp_file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Read image
        frame = cv2.imread(temp_file_path)
        gray_fr = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = facec.detectMultiScale(gray_fr, 1.3, 5)
        
        if len(faces) == 0:
            os.remove(temp_file_path)
            return {
                "status": "error",
                "message": "No face detected in the image"
            }
        
        # Process the first detected face
        x, y, w, h = faces[0]
        fc = gray_fr[y:y+h, x:x+w]
        roi = cv2.resize(fc, (48, 48))
        pred = faceModel.predict_emotion(roi[np.newaxis, :, :, np.newaxis])
        
        # Clean up
        os.remove(temp_file_path)
        
        return {
            "status": "success",
            "emotion": pred,
            "message": "Emotion detected successfully"
        }
        
    except Exception as e:
        # Clean up in case of error
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
            
        return {
            "status": "error",
            "message": f"Error processing image: {str(e)}"
        }


# send_notification
class NotificationRequest(BaseModel):
    userID: str
    type: str  # "heart_rate" or "emotion"
    emotion: str = None  # Only used if type is "emotion"
    
@app.post("/notifications/send")
async def send_notification(request: NotificationRequest):
    
    recipient_email = db.child("users").child(request.userID).child("emergency_contact").child("email").get().val()

    # Prepare notification details
    if request.type == "heart_rate":
        subject = "Urgent: Elevated Heart Rate Detected"
        content = (
            f"Dear Emergency Contact,\n\n"
            f"We detected an unusually high heart rate for the user associated with this contact. "
            f"They have requested emergency contact notification. Please check on them as soon as possible.\n\n"
            f"Best regards,"
        )
    elif request.type == "emotion" and request.emotion:
        subject = "Emotional Support Alert"
        content = (
            f"Dear Emergency Contact,\n\n"
            f"We noticed that the user is feeling {request.emotion}. "
            f"They have requested to notify their emergency contact for support.\n\n"
            f"Please check in with them if possible.\n\n"
            f"Best regards,"
        )
    else:
        raise HTTPException(status_code=400, detail="Invalid notification type or missing emotion")
        
    # Send email
    success = await send_email(recipient_email, subject, content)
    
    if success:
        return {"message": "Notification sent successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to send notification")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)