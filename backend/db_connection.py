import pyrebase
from fastapi import HTTPException

# Firebase configuration
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

# Initialize Firebase services
def initialize_firebase():
    """Initialize and return Firebase services."""
    try:
        firebase = pyrebase.initialize_app(firebaseConfig)
        auth = firebase.auth()
        db = firebase.database()
        storage = firebase.storage()
        return firebase, auth, db, storage
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Firebase initialization error: {str(e)}"
        )

# Get initialized Firebase services
firebase, auth, db, storage = initialize_firebase()

# Helper functions for common database operations
def get_user_profile(user_id):
    """Get user profile from the database."""
    try:
        profile = db.child("users").child(user_id).get().val()
        return profile
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving user profile: {str(e)}"
        )

def save_to_database(path, data):
    """Save data to specified path in the database."""
    try:
        return db.child(path).push(data)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error saving to database: {str(e)}"
        )

def update_database(path, data):
    """Update data at specified path in the database."""
    try:
        return db.child(path).update(data)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error updating database: {str(e)}"
        )

def get_from_database(path):
    """Get data from specified path in the database."""
    try:
        return db.child(path).get().val()
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving from database: {str(e)}"
        )

def authenticate_user(email, password):
    """Authenticate user with email and password."""
    try:
        user = auth.sign_in_with_email_and_password(email, password)
        return user
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Authentication failed: {str(e)}"
        )

def create_new_user(email, password):
    """Create a new user with email and password."""
    try:
        user = auth.create_user_with_email_and_password(email, password)
        return user
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"User creation failed: {str(e)}"
        )

def get_user_by_token(token):
    """Get user info from authentication token."""
    try:
        user = auth.get_account_info(token)
        return user['users'][0]
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )