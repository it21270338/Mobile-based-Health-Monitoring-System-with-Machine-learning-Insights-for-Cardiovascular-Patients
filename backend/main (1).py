from fastapi import FastAPI, HTTPException, UploadFile, File, Depends, Header, Query
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator, EmailStr
import joblib
import pandas as pd
from typing import Optional,Dict,Any,List
import uvicorn
from datetime import datetime,timedelta
from collections import Counter
import pyrebase
import shutil
import os
import torch
from PIL import Image
from transformers import (
    VisionEncoderDecoderModel,
    AutoTokenizer,
    ViTFeatureExtractor,
    ProphetNetForConditionalGeneration,
    ProphetNetTokenizer,
    pipeline,
)
import io
import numpy as np
import cv2
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
from tensorflow.keras.models import load_model
import pickle
import re
from tensorflow.keras.preprocessing.sequence import pad_sequences
import requests
from ultralytics import YOLO
from scipy import signal
from transformers import BertTokenizer, BertForSequenceClassification
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
import shap

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

firebaseConfig = {
  "apiKey": "AIzaSyCt__rHohtEZoUc_G9K70Fva-gv15JyQx4",
  "authDomain": "healthy-heart-c6bbd.firebaseapp.com",
  "databaseURL": "https://healthy-heart-c6bbd-default-rtdb.asia-southeast1.firebasedatabase.app",
  "projectId": "healthy-heart-c6bbd",
  "storageBucket": "healthy-heart-c6bbd.firebasestorage.app",
  "messagingSenderId": "177408255298",
  "appId": "1:177408255298:web:cd35c83702282b744654db",
  "measurementId": "G-P59RE9WSYV"
}

# Initialize Firebase
firebase = pyrebase.initialize_app(firebaseConfig)
auth = firebase.auth()
db = firebase.database()


# Load the model and scaler when app starts
try:
    model = joblib.load('cardio_rf_model.joblib')
    scaler = joblib.load('cardio_scaler.joblib')
except Exception as e:
    raise Exception(f"Error loading model or scaler: {str(e)}")

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Pydantic Models
class EmergencyContact(BaseModel):
    name: str
    email: EmailStr
    phone: str
    relationship: str
    
   
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    height: Optional[float] = None
    weight: Optional[float] = None 
    heart_rate: Optional[float] = 100
    emergency_contact: EmergencyContact


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# Helper Functions
async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        user = auth.get_account_info(token)
        return user['users'][0]
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def create_user_profile(user_id: str, user_data: Dict[str, Any]):
    """Create initial user profile in Firebase Realtime Database"""
    profile_data = {
        "profile": {
            "name": user_data["name"],
            "email": user_data["email"],
            "height": user_data.get("height"),
            "weight": user_data.get("weight"),
            "heart_rate": user_data.get("heart_rate"),
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
        user = auth.create_user_with_email_and_password(
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


    # Get user profile
@app.get("/users/{user_id}")
async def get_profile(user_id: str):
    """Get user profile from Firebase."""
    
    try:
        # Get profile from Firebase
        profile_data = db.child("users").child(user_id).get().val()
        
        if not profile_data:
            raise HTTPException(status_code=404, detail="Profile not found")
        
        return profile_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve profile: {str(e)}")


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    emergency_contact: Optional[EmergencyContact] = None

# Update user profile
@app.put("/users/{user_id}")
async def update_profile(
    user_id: str, 
    request_data: dict
):

    try:
        print("Received data:", request_data)
        user_ref = db.child("users").child(user_id)

        # Loop through each section like 'profile', 'emergency_contact'
        for section_key, section_data in request_data.items():
            user_ref.child(section_key).update(section_data)

        # Fetch and return updated data
        updated_data = user_ref.get().val()
        return updated_data

    except Exception as e:
        print(f"Error updating profile: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")


class HealthMetrics(BaseModel):
    heart_rate: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    last_updated: Optional[str] = None


# Get current health metrics
@app.get("/metrics/{user_id}", response_model=HealthMetrics)
async def get_health_metrics(
    user_id: str
):
    """Get the health metrics (heart rate, height, weight) from user profile."""
    # Security check - ensure user can only access their own data
 
    try:
        # Get profile from Firebase for all health metrics
        profile_data = db.child("users").child(user_id).child("profile").get().val()
        
        if not profile_data:
            raise HTTPException(status_code=404, detail="User profile not found")
        
        # Extract values from profile
        heart_rate = profile_data.get("heart_rate")
        height = profile_data.get("height")
        weight = profile_data.get("weight")
        
        return {
            "heart_rate": heart_rate,
            "height": height,
            "weight": weight,
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve health metrics: {str(e)}")
    

@app.post("/login")
async def login(user_data: UserLogin):
    try:
        # Sign in user with Firebase Authentication
        user = auth.sign_in_with_email_and_password(
            email=user_data.email,
            password=user_data.password
        )
        
        # Get user profile from Realtime Database
        profile = db.child("users").child(user['localId']).get().val()
        
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
    activity_level: Optional[int]
    bmi: float

class HealthRecordResponse(BaseModel):
    risk_level: str
    risk_probability: float
    bmi_category: str
    health_score: float
    recommendations: list[str]
    timestamp: str
    user_id: str

def describe_feature_value(feature: str, value):
    if feature == "smoking":
        return "smoking" if value == 1 else ""
    elif feature == "alcohol":
        return "alcohol consumption" if value == 1 else ""
    else:
        return f"{feature.replace('_', ' ')} ({value})"

@app.post("/predict_risk", response_model=HealthRecordResponse)
async def predict_risk(patient_data: PatientData, user_id: str):
    try:
        patient_dict = patient_data.dict()
        patient_df = pd.DataFrame([patient_dict])
        patient_scaled = scaler.transform(patient_df)

        # Prediction
        risk_prediction = model.predict(patient_scaled)[0]
        risk_probability = model.predict_proba(patient_scaled)[0][1] * 100
        health_score = calculate_health_score(patient_dict, risk_probability)
        bmi_category = get_bmi_category(patient_data.bmi)
        recommendations = get_health_recommendations(patient_dict, risk_probability)

        # SHAP explanation (class 1 risk)
        explainer = shap.TreeExplainer(model)
        shap_values = explainer(patient_scaled)
        
        shap_values_class1 = shap_values.values[0, :, 1]
        base_value_class1 = shap_values.base_values[0, 1]


        # Get top positively contributing features
        top_positive_features = [
            (feature, shap_val, patient_dict[feature])
            for feature, shap_val in zip(patient_df.columns, shap_values_class1)
            if shap_val > 0
        ]
        top_positive_features = sorted(top_positive_features, key=lambda x: abs(x[1]), reverse=True)[:3]

        
        # Construct explanation text
        feature_texts = [
            describe_feature_value(feature, value)
            for feature, _, value in top_positive_features
        ]
        
        
        reasoning = f"Because you have elevated levels in: {', '.join(feature_texts)}."

        # Timestamp and record
        timestamp = datetime.now().isoformat()
        health_record = {
            "risk_level": "High" if risk_prediction == 1 else "Low",
            "risk_probability": round(risk_probability, 1),
            "bmi_category": bmi_category,
            "health_score": round(health_score, 1),
            "recommendations": recommendations,
            "explanation": reasoning if risk_prediction == 1 else "",
            "timestamp": timestamp,
            "user_data": patient_dict
        }

        # Save to Firebase
        db.child("health_records").child(user_id).push(health_record)

        # Return response with explanation
        return HealthRecordResponse(
            risk_level="High" if risk_prediction == 1 else "Low",
            risk_probability=round(risk_probability, 1),
            bmi_category=bmi_category,
            health_score=round(health_score, 1),
            recommendations=recommendations + [reasoning if risk_prediction == 1 else ""],
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


@app.get("/health_records/{user_id}")
async def get_health_records(
    user_id: str,
    limit: int = Query(10, ge=1, le=100, description="Number of records to retrieve")
):
    try:
        # Get health records from Firebase
        health_records = db.child("health_records").child(user_id).get().val()
        
        if not health_records:
            return {"records": []}
        
        # Convert to list and add record ID
        records_list = [{"id": key, **value} for key, value in health_records.items()]
        
        # Sort by timestamp (newest first)
        records_list.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        
        # Apply limit
        if limit > 0 and limit < len(records_list):
            records_list = records_list[:limit]
        
        return {"records": records_list}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve health records: {str(e)}")

@app.put("/update_heart_rate/{user_id}")
async def update_heart_rate(
    user_id: str,
    heart_rate: int = Query(..., ge=20, le=220, description="Heart rate in bpm"),
):
    """Update a user's heart rate."""
    try:
        
        # Update heart rate in the user's profile
        profile_ref = db.child("users").child(user_id).child("profile")
        
        # Update data
        profile_ref.update({"heart_rate": heart_rate})
        
        return {
            "status": "success",
            "message": "Heart rate updated successfully",
            "heart_rate": heart_rate
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update heart rate: {str(e)}")

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

@app.get("/")
async def root():
    return {
        "message": "Heart Risk Prediction API",
        "endpoints": {
            "/predict": "POST endpoint for heart risk prediction",
        }
    }


# ECG Part

# Set the path to the final model directory
final_model_dir = os.path.abspath("final_ecg_model")

# Load model, tokenizer, and feature extractor
ecgmodel = VisionEncoderDecoderModel.from_pretrained(final_model_dir)
ecgtokenizer = AutoTokenizer.from_pretrained(final_model_dir)
feature_extractor = ViTFeatureExtractor.from_pretrained(final_model_dir)

# Load Question Generation model and tokenizer
QGmodel = ProphetNetForConditionalGeneration.from_pretrained("microsoft/prophetnet-large-uncased-squad-qg")
QGtokenizer = ProphetNetTokenizer.from_pretrained("microsoft/prophetnet-large-uncased-squad-qg")

# Load Question Answering pipeline
qa_pipeline = pipeline("question-answering", model="deepset/roberta-base-squad2")

# Move model to GPU if available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
ecgmodel.to(device)
QGmodel.to(device)

def generate_description(image_bytes, ecgmodel, feature_extractor, ecgtokenizer):
    """Generate description for a single image"""
    # Ensure model is in eval mode
    ecgmodel.eval()

    # Process image
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    pixel_values = feature_extractor(image, return_tensors="pt").pixel_values

    # Move input to same device as model
    pixel_values = pixel_values.to(device)

    with torch.no_grad():
        generated_ids = ecgmodel.generate(
            pixel_values, max_length=512, num_beams=4, length_penalty=2.0
        )

    generated_text = ecgtokenizer.decode(generated_ids[0], skip_special_tokens=True)
    return generated_text

def generate_questions(description):
    """Generate questions from the description"""
    inputs = QGtokenizer([description], return_tensors="pt", truncation=True, padding=True)
    inputs = {k: v.to(device) for k, v in inputs.items()}  # Move inputs to the correct device

    # Generate questions
    question_ids = QGmodel.generate(
        inputs["input_ids"], num_beams=5, num_return_sequences=3, early_stopping=True
    )
    questions = QGtokenizer.batch_decode(question_ids, skip_special_tokens=True)

    # Filter out questions that don't end with '?'
    valid_questions = [q.strip() for q in questions if q.strip().endswith("?")]

    # Add common questions (ensure they end with '?')
    common_questions = [
        "What is the rhythm observed in this ECG?",
        "What is the most likely diagnosis based on the ECG findings?",
        "What is the main cause of inferior leads?",
    ]
    valid_questions.extend(common_questions)

    return valid_questions

def get_answers(questions, context):
    """Get answers for the questions using the QA pipeline"""
    results = []
    
    results.append({"question": "Describe This ECG", "answer": context})
    
    for question in questions:
        result = qa_pipeline(question=question, context=context)
        if result["answer"]:  # Only include non-empty answers
            results.append({"question": question, "answer": result["answer"]})
    return results

def detect_periodic_waves(gray_img):
    """Detect periodic wave patterns characteristic of ECG"""
    height, width = gray_img.shape
    wave_scores = []

    for y in range(height // 4, 3 * height // 4, height // 10):
        if y >= height:
            break

        # Extract horizontal line profile
        line_profile = gray_img[y, :]

        # Smooth the profile
        line_profile = cv2.GaussianBlur(line_profile.reshape(1, -1), (5, 1), 0).flatten()

        # Find negative peaks (QRS-like)
        peaks, _ = signal.find_peaks(
            -line_profile,
            height=np.mean(line_profile) - 2 * np.std(line_profile),
            distance=width // 20
        )

        if len(peaks) >= 3:
            peak_intervals = np.diff(peaks)
            if len(peak_intervals) > 1:
                interval_std = np.std(peak_intervals)
                interval_mean = np.mean(peak_intervals)
                regularity = 1.0 - min(1.0, interval_std / (interval_mean + 1e-6))
                wave_scores.append(regularity * (len(peaks) / 10.0))

    return np.mean(wave_scores) if wave_scores else 0.0

def is_likely_ecg_core(image):
    """
    Determines if the PIL image is likely an ECG by combining gridline and waveform detection.
    """
    try:
        image = image.convert("RGB")
        cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        gray = cv2.cvtColor(cv_image, cv2.COLOR_BGR2GRAY)

        # ---------- Line Detection ----------
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLinesP(edges, 1, np.pi / 180, threshold=80, minLineLength=100, maxLineGap=10)

        horizontal_lines = 0
        if lines is not None:
            for line in lines:
                x1, y1, x2, y2 = line[0]
                angle = np.arctan2(y2 - y1, x2 - x1) * 180 / np.pi
                if abs(angle) < 10:
                    horizontal_lines += 1

        # ---------- Wave Pattern Detection ----------
        wave_score = detect_periodic_waves(gray)

        # ---------- Heuristic Rules ----------
        is_grid_ecg = horizontal_lines >= 5
        is_wave_ecg = wave_score < 0.3  # Tunable threshold

        return is_grid_ecg and is_wave_ecg

    except Exception as e:
        print(f"ECG detection failed: {e}")
        return False
    
def is_likely_ecg(image_bytes):
    try:
        # Convert bytes to PIL Image
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        return is_likely_ecg_core(image)  # Use core logic for actual detection
    except Exception as e:
        print(f"ECG detection failed: {e}")
        return False


@app.post("/upload-ecg/{user_id}")
async def upload_ecg(user_id: str, file: UploadFile = File(...)):
    try:
        # Create directory if it doesn't exist
        os.makedirs(f"uploads/{user_id}", exist_ok=True)

        # Save the file
        file_path = f"uploads/{user_id}/{file.filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Read the saved file as bytes
        with open(file_path, "rb") as image_file:
            image_bytes = image_file.read()
            
        if not is_likely_ecg(image_bytes):
            print("Uploaded image does not appear to be an ECG")
            return {
                "status": "false",
                "message": "Uploaded image does not appear to be an ECG"
            }

        # Generate description
        description = generate_description(image_bytes, ecgmodel, feature_extractor, ecgtokenizer)

        # Generate questions
        questions = generate_questions(description)

        # Get answers for the questions
        qa_results = get_answers(questions, description)
        
        # qa_results = [
        #     {
        #     "question": "is there a left axis deviation or prolonged qrs complex duration?",
        #     "answer": "left axis deviation"
        #     },
        #     {
        #     "question": "what does the ecg show?",
        #     "answer": "a regular rhythm at a rate of 60 bpm"
        #     },
        #     {
        #     "question": "What is the rhythm observed in this ECG?",
        #     "answer": "regular rhythm at a rate of 60 bpm"
        #     },
        #     {
        #     "question": "What is the most likely diagnosis based on the ECG findings?",
        #     "answer": "acute myocardial infarction"
        #     },
        #     {
        #     "question": "What is the main cause of inferior leads?",
        #     "answer": "st - segment elevation"
        #     }
        # ]
        
        qa_results.append({"question": "Describe This ECG", "answer": description})


        # Save reference in Firebase
        db.child("ecg_reports").child(user_id).push({
            "filename": file.filename,
            "path": file_path,
            "timestamp": datetime.now().isoformat(),
            "description": description,
            "questions_and_answers": qa_results,
        })

        return {
            "status": "success",
            "message": "File uploaded successfully",
            "description": description,
            "questions_and_answers": qa_results,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class ECGReportSummary(BaseModel):
    id: str
    filename: str
    timestamp: str
    short_description: str  # First 100 characters of the description

class ECGReportsList(BaseModel):
    reports: List[ECGReportSummary]
    total_count: int
    
class QA(BaseModel):
    question: str
    answer: str
    
class ECGReport(BaseModel):
    id: str
    filename: str
    path: str
    timestamp: str
    description: str
    questions_and_answers: List[QA]    


@app.get("/users/{user_id}/ecg-reports", response_model=ECGReportsList)
async def get_ecg_reports(
    user_id: str,
    limit: int = Query(10, description="Number of reports to return"),
    offset: int = Query(0, description="Skip first N reports"),
    sort_by: str = Query("timestamp", description="Field to sort by"),
    sort_order: str = Query("desc", description="Sort order (asc or desc)"),
):
    """
    Get a list of ECG reports for a user with pagination and sorting options.
    Returns a summary of each report.
    """
    try:
        # Get reports from Firebase
        reports_ref = db.child("ecg_reports").child(user_id).get()
        if not reports_ref.val():
            return {"reports": [], "total_count": 0}
        
        # Convert to list and add IDs
        reports = []
        for report_id, report_data in reports_ref.val().items():
            reports.append({
                "id": report_id,
                **report_data
            })
        
        # Sort reports
        reverse = sort_order.lower() == "desc"
        reports.sort(key=lambda x: x.get(sort_by, ""), reverse=reverse)
        
        # Apply pagination
        paginated_reports = reports[offset:offset+limit]
        
        # Create summary list
        report_summaries = []
        for report in paginated_reports:
            # Get first 100 characters of description for the summary
            short_desc = report.get("description", "")[:100] + "..." if len(report.get("description", "")) > 100 else report.get("description", "")
            
            report_summaries.append({
                "id": report["id"],
                "filename": report.get("filename", "Unknown"),
                "timestamp": report.get("timestamp", ""),
                "short_description": short_desc
            })
        
        return {
            "reports": report_summaries,
            "total_count": len(reports)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}/ecg-reports/{report_id}", response_model=ECGReport)
async def get_ecg_report_detail(
    user_id: str,
    report_id: str
):
    """
    Get detailed information about a specific ECG report
    """
    try:
        # Get report from Firebase
        report_ref = db.child("ecg_reports").child(user_id).child(report_id).get()
        if not report_ref.val():
            raise HTTPException(status_code=404, detail="Report not found")
        
        report_data = report_ref.val()
        
        return {
            "id": report_id,
            **report_data
        }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))


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


def predict_risk_heart(new_data: dict) -> str:
    # Load model and encoders
    model = joblib.load("heart_risk_model.pkl")
    label_encoders = joblib.load("label_encoders.pkl")
    target_encoder = joblib.load("target_encoder.pkl")

    # Encode categorical features
    for col in ['activity_type', 'pain_location', 'accompanying_symptoms']:
        new_data[col] = label_encoders[col].transform([new_data[col]])[0]

    # Prepare DataFrame for prediction
    input_df = pd.DataFrame([new_data])

    # Predict and decode label
    encoded_prediction = model.predict(input_df)[0]
    return target_encoder.inverse_transform([encoded_prediction])[0]

@app.post("/predict_heart_risk")
def predict_heart_risk(user_id: str, data: RiskPredictionRequest):
    """Predict risk level based on input data"""

    # Predict risk
    predicted_risk = predict_risk_heart(data.dict())
    
    # Create pain record
    record = {
        "timestamp": datetime.now().isoformat(),
        **data.dict(),
        "risk_level": predicted_risk
    }
    print(record)
        
    # Save to Firebase
    db.child("users").child(user_id).child("pain_records").push(record)
        
    # Update statistics
    update_user_statistics(user_id)

    return {"predicted_risk_level": predicted_risk}


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


def send_sms(recipient_phone, message):
    url = "https://app.notify.lk/api/v1/send"
    payload = {
        'user_id': "29578",
        'api_key': "HAFDUlJs5jBCXSIg2O45",
        'sender_id': "NotifyDEMO",
        'to': recipient_phone,
        'message': message
    }

    try:
        response = requests.get(url, params=payload)
        response.raise_for_status()  # Raise an error for bad status codes
        return response.json()
    except requests.RequestException as e:
        return {'status': 'error', 'message': str(e)}

def format_phone_number(phone):
    if phone.startswith("0"):
        return "94" + phone[1:]
    return phone

# send_notification
class NotificationRequest(BaseModel):
    userID: str
    type: str  # "heart_rate" or "emotion"
    emotion: str = None  # Only used if type is "emotion"
    
@app.post("/notifications/send")
async def send_notification(request: NotificationRequest):
    
    recipient_phone = db.child("users").child(request.userID).child("emergency_contact").child("phone").get().val()

    # Prepare notification details
    if request.type == "heart_rate":
        content = (
            f"Dear Emergency Contact,\n\n"
            f"We detected an unusually high heart rate for the user associated with this contact. "
            f"They have requested emergency contact notification. Please check on them as soon as possible.\n\n"
        )
    elif request.type == "emotion" and request.emotion:
        content = (
            f"Dear Emergency Contact,\n\n"
            f"We noticed that the user is feeling {request.emotion}. "
            f"They have requested to notify their emergency contact for support.\n\n"
            f"Please check in with them if possible.\n\n"
        )
    else:
        raise HTTPException(status_code=400, detail="Invalid notification type or missing emotion")
        
    
    formatted_phone = format_phone_number(recipient_phone)
    # Send email
    success = await send_sms(formatted_phone, content)
    
    if success:
        return {"message": "Notification sent successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to send notification")


# emotion detection

lemmatizer = WordNetLemmatizer()
stop_words = set(stopwords.words('english'))

# # Input model
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
    text = re.sub('[%s]' % re.escape("""!"#$%&'()*+,?-./:;<=>??@[\]^_`{|}~"""), ' ', text)
    text = text.replace('?', "")
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

# Load model & tokenizer from local folder
emotion_text_model = BertForSequenceClassification.from_pretrained("emotion-bert-model")
emotion_text_tokenizer = BertTokenizer.from_pretrained("emotion-bert-model")

label_columns = ['anger', 'anticipation', 'disgust', 'fear', 'joy', 'love',
                 'optimism', 'pessimism', 'sadness', 'surprise', 'trust']

def predict_emotions_best(text, threshold=0.5):
    emotion_text_model.eval()
    # Detect model device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    emotion_text_model.to(device)

    # Tokenize and move input to same device
    inputs = emotion_text_tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=128)
    inputs = {k: v.to(device) for k, v in inputs.items()}

    # Get logits from model
    with torch.no_grad():
        outputs = emotion_text_model(**inputs)
        logits = outputs.logits
        probs = torch.sigmoid(logits).squeeze().cpu().numpy()  # move back to CPU for numpy

    # Threshold to get binary predictions
    pred_vector = (probs >= threshold).astype(int)

    # Filter predicted labels with their scores
    predicted = [(label_columns[i], probs[i]) for i, val in enumerate(pred_vector) if val == 1]

    # Return best label among those predicted
    if predicted:
        best = max(predicted, key=lambda x: x[1])  # highest score among predicted
        return best  # returns tuple: (label, score)
    else:
        return None  # or ('none', 0.0)

@app.post("/predictEmotion")
async def predict_emotion(input_data: SentenceInput, user_id: str) -> Dict:
    # Preprocess the input sentence
    sentence = normalized_sentence(input_data.sentence)
    print(f"Processed sentence: {sentence}")
    
    prediction, probability = predict_emotions_best(sentence)
    print(f"Prediction: {prediction}, Probability: {probability}")
    
    probability = float(np.max(probability))
    
    # Prepare data to store
    emotion_record = {
        "emotion": prediction,
        "probability": probability,
        "timestamp": datetime.now().isoformat()
    }

    # Save to Firebase under user node
    try:
        db.child("emotions").child(user_id).push(emotion_record)
    except Exception as e:
        print(f"Failed to store emotion: {e}")
    
    return {
        "emotion": prediction,
        "probability": probability
    }

@app.post("/predict-emotion-image")
async def predict_emotion_image(user_id:str,file: UploadFile = File(...)) -> Dict:
    yolomodel = YOLO("affectnet_yolo_model.pt")
    try:
        # Save uploaded file temporarily
        temp_file_path = f"temp_{file.filename}"
        with open(temp_file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
            

        # Load image using OpenCV
        img = cv2.imread(temp_file_path)
        if img is None:
            os.remove(temp_file_path)
            return {"status": "error", "message": "Invalid image format or unreadable image"}
        

        # Run inference
        results = yolomodel(img)
        # print(f"[DEBUG] Inference results: {results}")

        # Parse results
        predictions = []
        for box in results[0].boxes.data.tolist():
            x1, y1, x2, y2, score, cls = box
            predictions.append({
                "bbox": [int(x1), int(y1), int(x2), int(y2)],
                "confidence": float(score),
                "emotion": yolomodel.names[int(cls)]
            })

        # Cleanup
        os.remove(temp_file_path)

        if not predictions:
            return {"status": "error", "message": "No emotion detected."}
        
        # Prepare data to store
        emotion_record = {
            "emotion": predictions[0]["emotion"],
            "probability": predictions[0]["confidence"],
            "timestamp": datetime.now().isoformat()
        }

        # Save to Firebase under user node
        try:
            db.child("emotions").child(user_id).push(emotion_record)
        except Exception as e:
            print(f"Failed to store emotion: {e}")

        return {
            "status": "success",
            "message": "Emotion detected successfully",
            "emotion": predictions[0]["emotion"],
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/users/{user_id}/emotions/analytics")
async def get_emotion_analytics(
    user_id: str,
    time_range: str = Query("week", description="Time range filter: day, week, month, all"),
    emotion_filter: Optional[str] = Query(None, description="Filter by specific emotion")
):
    # Get all emotions for this user
    emotions_data = db.child("emotions").child(user_id).get().val()
    
    if not emotions_data:
        return {
            "distribution": [],
            "frequency": [],
            "total_records": 0,
            "time_range": time_range
        }
    
    # Calculate date filter based on time_range
    now = datetime.now()
    date_filter = None
    
    if time_range == "day":
        date_filter = now - timedelta(days=1)
    elif time_range == "week":
        date_filter = now - timedelta(weeks=1)
    elif time_range == "month":
        date_filter = now - timedelta(days=30)
    
    # Process and filter emotions
    filtered_emotions = []
    
    for record_id, data in emotions_data.items():
        record_time = datetime.fromisoformat(data["timestamp"])
        
        # Apply time filter if specified
        if date_filter and record_time < date_filter:
            continue
            
        # Apply emotion filter if specified
        if emotion_filter and data["emotion"] != emotion_filter:
            continue
            
        filtered_emotions.append(data)
    
    # Count emotion occurrences
    emotion_counter = Counter([e["emotion"] for e in filtered_emotions])
    total_count = len(filtered_emotions)
    
    # Calculate distribution (for pie chart)
    distribution = [
        {
            "emotion": emotion,
            "count": count,
            "percentage": round(count / total_count * 100, 2) if total_count > 0 else 0
        }
        for emotion, count in emotion_counter.items()
    ]
    
    # Sort by count for frequency (for bar chart)
    frequency = [
        {
            "emotion": emotion,
            "count": count
        }
        for emotion, count in sorted(emotion_counter.items(), key=lambda x: x[1], reverse=True)
    ]
    
    return {
        "distribution": distribution,
        "frequency": frequency,
        "total_records": total_count,
        "time_range": time_range
    }
    
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)