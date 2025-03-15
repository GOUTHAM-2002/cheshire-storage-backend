from flask_cors import CORS
from app import app, supabase
from flask import request, jsonify
import os

# Configure CORS
CORS(app, resources={
    r"/api/*": {
        "origins": [
            "https://your-netlify-app.netlify.app",  # Update with your Netlify URL
            "http://localhost:8080",
            "http://localhost:3000"
        ]
    }
})
from werkzeug.security import generate_password_hash

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.json
    print("Received registration data:", data)
    try:
        # Create auth user
        auth_response = supabase.auth.sign_up({
            "email": data['email'],
            "password": data['password']
        })
        
        user_id = auth_response.user.id
        
        # Create user profile
        user_data = {
            "id": user_id,
            "first_name": data['firstName'],
            "last_name": data['lastName'],
            "email": data['email'],
            "phone": data['phone'],
            "user_type": data['userType']
        }
        
        print("User data to insert:", user_data)
        
        supabase.table('users').insert(user_data).execute()
        
        # If registering as owner, create owner details
        if data['userType'] == 'owner':
            owner_data = {
                "user_id": user_id,  # Changed from id to user_id
                "company_name": data['companyName'],
                "headquarters": data['headquarters'],
                "total_properties": int(data['totalProperties']) if data['totalProperties'] else 0
            }
            supabase.table('owner_details').insert(owner_data).execute()
        
        return jsonify({"message": "Registration successful"}), 201
        
    except Exception as e:
        print("Registration error:", str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.json
    try:
        response = supabase.auth.sign_in_with_password({
            "email": data['email'],
            "password": data['password']
        })
        
        # Extract only the necessary user data
        user_data = {
            "id": response.user.id,
            "email": response.user.email,
            "created_at": str(response.user.created_at)
        }
        
        return jsonify({
            "token": response.session.access_token,
            "user": user_data
        }), 200
        
    except Exception as e:
        print("Login error:", str(e))  # Add debugging
        return jsonify({"error": str(e)}), 401

@app.route('/api/contact', methods=['POST'])
def submit_contact():
    data = request.json
    try:
        contact_data = {
            "name": data['name'],
            "email": data['email'],
            "subject": data['subject'],
            "message": data['message']
        }
        
        supabase.table('contact_messages').insert(contact_data).execute()
        
        return jsonify({"message": "Message sent successfully"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/auth/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.json
        email = data.get('email')
        
        if not email:
            return jsonify({"error": "Email is required"}), 400

        # Supabase password reset with redirect URL
        response = supabase.auth.reset_password_email(
            email,
            options={
                "redirect_to": "http://localhost:8080/reset-password"  # Frontend URL
            }
        )
        
        return jsonify({
            "message": "Password reset email sent successfully"
        }), 200
        
    except Exception as e:
        print("Password reset error:", str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/api/auth/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.json
        auth_header = request.headers.get('Authorization')
        
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Invalid authorization header"}), 401
            
        access_token = auth_header.split(' ')[1]
        refresh_token = data.get('refresh_token')
        
        if not refresh_token:
            return jsonify({"error": "Refresh token is required"}), 400
        
        # Set the session with both tokens
        supabase.auth.set_session(access_token, refresh_token)
        
        # Update password in Supabase
        response = supabase.auth.update_user({
            "password": data['password']
        })
        
        return jsonify({
            "message": "Password updated successfully"
        }), 200
        
    except Exception as e:
        print("Password update error:", str(e))
        return jsonify({"error": str(e)}), 400