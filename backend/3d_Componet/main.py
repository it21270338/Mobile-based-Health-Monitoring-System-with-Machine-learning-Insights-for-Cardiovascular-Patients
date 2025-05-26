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

# Load trained model and encoders
health_model = joblib.load("health_risk_model.pkl")
health_label_encoder = joblib.load("health_label_encoder.pkl")
health_scaler = joblib.load("health_scaler.pkl")
expected_features = joblib.load("health_feature_names.pkl")  # Load saved feature names

# Load saved classes for handling unseen labels
activity_classes = np.load("activity_type_classes.npy", allow_pickle=True)
pain_location_classes = np.load("pain_location_classes.npy", allow_pickle=True)
symptoms_classes = np.load("accompanying_symptoms_classes.npy", allow_pickle=True)


# Input validation model
class RiskPredictionRequest(BaseModel):
    heart_rate: float
    pain_duration_minutes: float
    activity_type: str
    pain_location: str
    accompanying_symptoms: str

# Function to encode categories safely
def encode_with_fallback(value, known_classes):
    """Returns encoded value if known, else assigns a default (-1)."""
    if value in known_classes:
        return np.where(known_classes == value)[0][0]  # Get the index
    else:
        return -1  # Assign -1 for unseen labels

@app.post("/predict_heart_risk")        #endpoint
def predict_heart_risk(user_id: str, data: RiskPredictionRequest):
    """Predict risk level based on input data"""
    input_df = pd.DataFrame([data.dict()])
    
    # Encode categorical features safely
    input_df['activity_type'] = input_df['activity_type'].apply(lambda x: encode_with_fallback(x, activity_classes))
    input_df['pain_location'] = input_df['pain_location'].apply(lambda x: encode_with_fallback(x, pain_location_classes))
    input_df['accompanying_symptoms'] = input_df['accompanying_symptoms'].apply(lambda x: encode_with_fallback(x, symptoms_classes))

    # Scale numerical features
    numerical_features = ['heart_rate', 'pain_duration_minutes']
    input_df[numerical_features] = health_scaler.transform(input_df[numerical_features])

    # Ensure feature order matches training
    input_df = input_df.reindex(columns=expected_features, fill_value=0)  # Fill missing columns with 0

    # Predict risk
    prediction = health_model.predict(input_df)     #get prediction
    predicted_risk = health_label_encoder.inverse_transform(prediction)
    
    # Create pain record
    record = {
        "timestamp": datetime.now().isoformat(),
        **data.dict(),
        "risk_level": predicted_risk[0]
    }
    print(record)
        
    # Save to Firebase
    db.child("users").child(user_id).child("pain_records").push(record)
        
    # Update statistics
    update_user_statistics(user_id)

    return {"predicted_risk_level": predicted_risk[0]}

class PainRecord(RiskPredictionRequest):
    timestamp: str
    risk_level: str
    user_id: str

class UserProfile(BaseModel):
    name: str
    age: int
    gender: str
    
@app.post("/save_pain_record/{user_id}")
async def save_pain_record(user_id: str, data: RiskPredictionRequest):
    """Save pain record to Firebase"""
    try:
        # Get risk prediction
        risk_prediction = predict_heart_risk(data)
        
        # Create pain record
        record = {
            "timestamp": datetime.now().isoformat(),
            **data.dict(),
            "risk_level": risk_prediction["predicted_risk_level"]
        }
        
        # Save to Firebase
        db.child("users").child(user_id).child("pain_records").push(record)
        
        # Update statistics
        update_user_statistics(user_id)
        
        return {"status": "success", "message": "Pain record saved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get_pain_history/{user_id}")
async def get_pain_history(user_id: str, time_range: Optional[str] = "all"):
    """Get pain history with analytics"""
    try:
        # Get pain records
        records = db.child("users").child(user_id).child("pain_records").get()
        
        if not records.each():
            return {
                "pain_history": [],
                "insights": [],
                "location_frequencies": {},
                "symptom_correlations": {}
            }
        
        # Convert to list and prepare for analysis
        history = []
        for record in records.each():
            record_data = record.val()
            # Convert any numpy integers to Python integers
            for key, value in record_data.items():
                if isinstance(value, np.integer):
                    record_data[key] = int(value)
                elif isinstance(value, np.floating):
                    record_data[key] = float(value)
            history.append(record_data)
        
        # Convert to DataFrame
        df = pd.DataFrame(history)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        # Apply time range filter if specified
        if time_range != "all":
            df = filter_by_time_range(df, time_range)
        
        # Generate analytics
        insights = generate_insights(df)
        location_frequencies = calculate_location_frequencies(df)
        symptom_correlations = analyze_symptom_patterns(df)
        
        return {
            "pain_history": history,
            "insights": insights,
            "location_frequencies": location_frequencies,
            "symptom_correlations": symptom_correlations
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get_user_statistics/{user_id}")
async def get_user_statistics(user_id: str):
    """Get user's pain statistics"""
    try:
        stats = db.child("users").child(user_id).child("statistics").get().val()
        return stats or {}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Helper Functions
def update_user_statistics(user_id: str):
    """Update user statistics based on pain records"""
    records = db.child("users").child(user_id).child("pain_records").get()
    if not records.each():
        return
    
    df = pd.DataFrame([record.val() for record in records.each()])
    
    statistics = {
        "most_common_pain_location": df['pain_location'].mode().iloc[0],
        "average_heart_rate": round(df['heart_rate'].mean(), 2),
        "total_records": len(df),
        "last_updated": datetime.now().isoformat()
    }
    
    db.child("users").child(user_id).child("statistics").set(statistics)

def generate_insights(df: pd.DataFrame) -> list[str]:
    """Generate insights from pain records"""
    insights = []
    
    if not df.empty:
        # Most common pain location
        common_location = df['pain_location'].mode().iloc[0]
        insights.append(f"Most frequent pain occurs in the {common_location}")
        
        # Activity correlation
        activity_pain = df.groupby('activity_type')['pain_duration_minutes'].mean()
        high_pain_activity = activity_pain.idxmax()
        insights.append(f"Pain duration tends to be highest during {high_pain_activity}")
        
        # Heart rate patterns
        avg_hr = df['heart_rate'].mean()
        insights.append(f"Average heart rate during pain episodes: {round(avg_hr)} BPM")
        
        # Risk level distribution
        risk_dist = df['risk_level'].value_counts()
        insights.append(f"Risk level distribution: {dict(risk_dist)}")
        
        # Symptom patterns
        common_symptoms = df['accompanying_symptoms'].mode().iloc[0]
        insights.append(f"Most common accompanying symptom: {common_symptoms}")
    
    return insights

def calculate_location_frequencies(df: pd.DataFrame) -> dict:
    """Calculate pain location frequencies"""
    # Convert numpy.int64 to regular Python int
    freq_dict = df['pain_location'].value_counts().to_dict()
    return {k: int(v) for k, v in freq_dict.items()}

def analyze_symptom_patterns(df: pd.DataFrame) -> dict:
    """Analyze patterns in symptoms"""
    patterns = {}
    
    if not df.empty:
        # Symptom and heart rate correlation
        symptom_hr = df.groupby('accompanying_symptoms')['heart_rate'].mean()
        patterns['symptom_heart_rate'] = {k: float(v) for k, v in dict(symptom_hr.round(2)).items()}
        
        # Symptom and risk level correlation
        symptom_risk = df.groupby(['accompanying_symptoms', 'risk_level']).size().unstack(fill_value=0)
        patterns['symptom_risk_distribution'] = {
            k: {inner_k: int(inner_v) for inner_k, inner_v in v.items()}
            for k, v in symptom_risk.to_dict().items()
        }
        
        # Symptom and activity correlation
        symptom_activity = df.groupby(['accompanying_symptoms', 'activity_type']).size()
        # Convert tuple keys to string format
        patterns['common_symptom_activities'] = {
            f"{symptom}_{activity}": int(count)
            for (symptom, activity), count in symptom_activity.nlargest(5).items()
        }
    
    return patterns
    
def filter_by_time_range(df: pd.DataFrame, time_range: str) -> pd.DataFrame:
    """Filter DataFrame by time range"""
    now = pd.Timestamp.now()
    
    if time_range == "day":
        return df[df['timestamp'] >= now - pd.Timedelta(days=1)]
    elif time_range == "week":
        return df[df['timestamp'] >= now - pd.Timedelta(weeks=1)]
    elif time_range == "month":
        return df[df['timestamp'] >= now - pd.Timedelta(days=30)]
    elif time_range == "year":
        return df[df['timestamp'] >= now - pd.Timedelta(days=365)]
    
    return df

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