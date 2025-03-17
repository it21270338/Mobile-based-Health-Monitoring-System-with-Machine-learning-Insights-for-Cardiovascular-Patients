from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator, EmailStr
import joblib
import pandas as pd
from typing import Optional, Dict, Any
import uvicorn
from datetime import datetime
import io
import numpy as np
from notification_service.email_sender import send_email

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

# Load the model and scaler when app starts
try:
    model = joblib.load('cardio_rf_model.joblib')
    scaler = joblib.load('cardio_scaler.joblib')
except Exception as e:
    raise Exception(f"Error loading model or scaler: {str(e)}")

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

# Define the request body model with validation
class PatientData(BaseModel):
    heart_rate: float
    blood_sugar: float
    height: float
    weight: float
    cholesterol: float
    smoking: int
    alcohol: int
    activity_level: int
    bmi: float

    # Add validation for the input fields
    @validator('heart_rate')
    def validate_heart_rate(cls, v):
        if not 40 <= v <= 200:
            raise ValueError('Heart rate must be between 40 and 200')
        return v

    @validator('blood_sugar')
    def validate_blood_sugar(cls, v):
        if not 50 <= v <= 400:
            raise ValueError('Blood sugar must be between 50 and 400')
        return v

    @validator('height')
    def validate_height(cls, v):
        if not 100 <= v <= 250:
            raise ValueError('Height must be between 100 and 250 cm')
        return v

    @validator('weight')
    def validate_weight(cls, v):
        if not 30 <= v <= 300:
            raise ValueError('Weight must be between 30 and 300 kg')
        return v

    @validator('cholesterol')
    def validate_cholesterol(cls, v):
        if not 100 <= v <= 500:
            raise ValueError('Cholesterol must be between 100 and 500')
        return v

    @validator('smoking', 'alcohol', 'activity_level')
    def validate_binary(cls, v):
        if v not in [0, 1]:
            raise ValueError('Value must be 0 or 1')
        return v

    @validator('bmi')
    def validate_bmi(cls, v):
        if not 10 <= v <= 50:
            raise ValueError('BMI must be between 10 and 50')
        return v

class HealthRecordResponse(BaseModel):
    risk_level: str
    risk_probability: float
    bmi_category: str
    health_score: float
    recommendations: list[str]
    timestamp: str
    user_id: str
    
@app.post("/predict_risk", response_model=HealthRecordResponse)
async def predict_risk(patient_data: PatientData, user_id: str):
    try:
        # Your existing prediction code...
        patient_dict = patient_data.dict()
        patient_df = pd.DataFrame([patient_dict])
        patient_scaled = scaler.transform(patient_df)
        
        risk_prediction = model.predict(patient_scaled)[0]
        risk_probability = model.predict_proba(patient_scaled)[0][1] * 100
        health_score = calculate_health_score(patient_dict, risk_probability)
        bmi_category = get_bmi_category(patient_data.bmi)
        recommendations = get_health_recommendations(patient_dict, risk_probability)
        
        # Create health record
        timestamp = datetime.now().isoformat()
        health_record = {
            "risk_level": "High" if risk_prediction == 1 else "Low",
            "risk_probability": round(risk_probability, 1),
            "bmi_category": bmi_category,
            "health_score": round(health_score, 1),
            "recommendations": recommendations,
            "timestamp": timestamp,
            "user_data": {
                "heart_rate": patient_data.heart_rate,
                "blood_sugar": patient_data.blood_sugar,
                "height": patient_data.height,
                "weight": patient_data.weight,
                "cholesterol": patient_data.cholesterol,
                "smoking": patient_data.smoking,
                "alcohol": patient_data.alcohol,
                "bmi": patient_data.bmi
            }
        }
        
        # Save to Firebase
        db.child("health_records").child(user_id).push(health_record)
        
        return HealthRecordResponse(
            risk_level="High" if risk_prediction == 1 else "Low",
            risk_probability=round(risk_probability, 1),
            bmi_category=bmi_category,
            health_score=round(health_score, 1),
            recommendations=recommendations,
            timestamp=timestamp,
            user_id=user_id
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health-records/{user_id}/{period}")
async def get_health_records(user_id: str, period: str):
    try:
        # Get all records for the user
        records = db.child("health_records").child(user_id).get()
        
        if not records.each():
            return {"records": []}
            
        # Convert to list and sort by timestamp
        health_records = []
        for record in records.each():
            data = record.val()
            data['id'] = record.key()
            health_records.append(data)
            
        health_records.sort(key=lambda x: x['timestamp'])
        
        # Filter based on period if needed
        filtered_records = filter_records_by_period(health_records, period)
        
        return {"records": filtered_records}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def filter_records_by_period(records: list, period: str) -> list:
    """Filter records based on daily/weekly/monthly period"""
    now = datetime.now()
    filtered = []
    
    for record in records:
        record_date = datetime.fromisoformat(record['timestamp'])
        
        if period == 'daily' and (now - record_date).days <= 7:
            filtered.append(record)
        elif period == 'weekly' and (now - record_date).days <= 30:
            filtered.append(record)
        elif period == 'monthly' and (now - record_date).days <= 180:
            filtered.append(record)
            
    return filtered


# Define the response model
class RiskPrediction(BaseModel):
    risk_level: str
    risk_probability: float
    bmi_category: str
    health_score: float
    recommendations: list[str]

def calculate_health_score(patient_data: dict, risk_probability: float) -> float:
    """Calculate overall health score based on various factors"""
    score = 100  # Start with perfect score
    
    # Deduct points based on risk probability
    score -= risk_probability * 0.3
    
    # BMI deductions
    if patient_data['bmi'] > 30:  # Obese
        score -= 10
    elif patient_data['bmi'] > 25:  # Overweight
        score -= 5
        
    # Lifestyle deductions
    if patient_data['smoking'] == 1:
        score -= 15
    if patient_data['alcohol'] == 1:
        score -= 10
    if patient_data['activity_level'] == 0:
        score -= 10
        
    return max(0, min(100, score))  # Ensure score is between 0 and 100

def get_bmi_category(bmi: float) -> str:
    if bmi < 18.5:
        return "Underweight"
    elif bmi < 25:
        return "Normal weight"
    elif bmi < 30:
        return "Overweight"
    else:
        return "Obese"

def get_health_recommendations(patient_data: dict, risk_probability: float) -> list[str]:
    recommendations = []
    
    if risk_probability > 30:
        recommendations.append("Schedule regular check-ups with your healthcare provider")
    
    if patient_data['smoking'] == 1:
        recommendations.append("Consider smoking cessation programs")
    
    if patient_data['alcohol'] == 1:
        recommendations.append("Limit alcohol consumption")
        
    if patient_data['activity_level'] == 0:
        recommendations.append("Increase physical activity to at least 150 minutes per week")
        
    if patient_data['bmi'] > 25:
        recommendations.append("Work on weight management through diet and exercise")
        
    if patient_data['cholesterol'] > 200:
        recommendations.append("Monitor cholesterol levels and consider dietary changes")
        
    return recommendations

@app.get("/latest-health-records/{user_id}/latest")
async def get_latest_health_record(user_id: str):
    
    try:
        # Get all records for the user
        records = db.child("health_records").child(user_id).get()
        
        if not records.each():
            return {
                "health_score": 0,
                "risk_level": "Unknown",
                "risk_probability": 0
            }
            
        # Convert to list and sort by timestamp
        health_records = []
        for record in records.each():
            data = record.val()
            data['id'] = record.key()
            health_records.append(data)
            
        # Sort by timestamp and get the latest
        health_records.sort(key=lambda x: x['timestamp'], reverse=True)
        latest_record = health_records[0]
        
        return {
            "health_score": latest_record['health_score'],
            "risk_level": latest_record['risk_level'],
            "risk_probability": latest_record['risk_probability']
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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