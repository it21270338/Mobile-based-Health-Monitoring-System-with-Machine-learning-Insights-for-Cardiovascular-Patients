import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:MediSafe/models/questions_and_answers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

var options = BaseOptions(
  // baseUrl: 'http://13.203.212.95:8000',
    baseUrl: 'http://13.203.212.95:8000',
  //   baseUrl: 'http://192.168.1.169:8000',

);
var options2 = BaseOptions(
  baseUrl: 'https://pleasing-pup-positive.ngrok-free.app',
  //dulanrashmika3@gmail.com   baseUrl: 'http://13.203.212.95:8000',
  //   baseUrl: 'http://192.168.1.169:8000',
);

var dio = Dio(options);
var dio2 = Dio(options);

class apiDio {
  late SharedPreferences prefs;

  // Constructor to initialize SharedPreferences
  apiDio() {
    _initPrefs();
  }
  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Login data structure
  Map<String, dynamic> loginData(String email, String password) {
    return {
      'email': email,
      'password': password,
    };
  }

  // Registration data structure
  Map<String, dynamic> registrationData({
    required String name,
    required String email,
    required String password,
    required String emergencyContactName,
    required String emergencyContactEmail,
    required String emergencyContactPhone,
    required String relationship,
    required String height,  // New parameter
    required String weight,  // New parameter
  }) {
    return {
      'name': name,
      'email': email,
      'password': password,
      'height': double.tryParse(height) ?? 0,  // Convert to double
      'weight': double.tryParse(weight) ?? 0,  // Convert to double
      'emergency_contact': {
        'name': emergencyContactName,
        'email': emergencyContactEmail,
        'phone': emergencyContactPhone,
        'relationship': relationship,
      },
    };
  }

  Future<bool> login(String email, String password, BuildContext context) async {
    try {
      final loginPayload = loginData(email, password);

      final response = await dio.post(
        '/login',
        data: json.encode(loginPayload),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        // Save auth token and user data
        final token = response.data['access_token'];
        final userId = response.data['user_id'];
        final profile = response.data['profile'];
        print(profile);

        await prefs.setString('token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_profile', json.encode(profile));

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        return true;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      String errorMessage = 'Login failed';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String familyName,
    required String familyEmail,
    required String familyPhone,
    required String relationship,
  }) async {
    try {
      final response = await dio.post(
        "/register",
        data: {
          "name": name,
          "email": email,
          "password": password,
          "emergency_contact": {
            "name": familyName,
            "email": familyEmail,
            "phone": familyPhone,
            "relationship": relationship,
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data; // Registration successful
      } else {
        throw Exception("Registration failed");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Registration error: $e");
    }
  }


  Future<Map<String, dynamic>> register({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String emergencyContactName,
    required String emergencyContactEmail,
    required String emergencyContactPhone,
    required String relationship,
    required String height,  // New parameter
    required String weight,  // New parameter
  }) async {
    try {
      final registrationPayload = registrationData(
        name: name,
        email: email,
        password: password,
        emergencyContactName: emergencyContactName,
        emergencyContactEmail: emergencyContactEmail,
        emergencyContactPhone: emergencyContactPhone,
        relationship: relationship,
        height: height,  // Pass height
        weight: weight,  // Pass weight
      );

      final response = await dio.post(
        '/register',
        data: json.encode(registrationPayload),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Registration failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(errorMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final token = prefs.getString('token');

      if (token != null) {
        await dio.post(
          '/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }

      // Clear stored data
      await prefs.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add auth token to requests
  Future<void> addAuthToken(RequestOptions options) async {
    final token = prefs.getString('token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> getUserProfile(BuildContext context) async {
    try {
      // Get user ID from SharedPreferences
      await _initPrefs();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('User is not logged in');
      }

      // Make API request
      final response = await dio.get(
        '/users/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Save profile data to SharedPreferences
        final profileData = response.data;
        print(profileData);
        await prefs.setString('user_profile', json.encode(profileData));

        return profileData;
      } else {
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load profile';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(errorMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      BuildContext context,
      Map<String, dynamic> profileData,
      ) async {
    try {
      // Get user ID from SharedPreferences
      await _initPrefs();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('User is not logged in');
      }

      final apiData = {
        'name': profileData['profile']['name'],
        'height': profileData['profile']['height'],
        'weight': profileData['profile']['weight'],
        'emergency_contact': profileData['emergency_contact']
      };
      print(apiData);
      // Make API request
      final response = await dio.put(
        '/users/$userId',
        data: profileData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        // Save updated profile data to SharedPreferences
        final updatedProfile = response.data;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        return updatedProfile;
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update profile';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(errorMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(e.toString());
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final profileString = prefs.getString('user_profile');
    if (profileString != null) {
      return json.decode(profileString);
    }
    return null;
  }

  // predict Emotion via Text

  Map<String, dynamic> emotionData(String sentence) {
    return {
      'sentence': sentence,
    };
  }

  Future<Map<String, dynamic>> predictEmotion(String sentence, String userId) async {
    try {
      var emotion_data = emotionData(sentence);
      String dataJson = json.encode(emotion_data);

      Response response = await dio2.post(
        '/predictEmotion',
        data: dataJson,
        queryParameters: {
          'user_id': userId, // 👈 Send userId in query
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      // Handle response
      if (response.statusCode == 200) {
        print("Predicted Emotion: ${response.data['emotion']}");
        return {
          'emotion': response.data['emotion'],
          'probability': response.data['probability'],
          'status': 'success'
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to predict emotion',
        };
      }
    } catch (e) {
      print('Error predicting emotion: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }


  Map<String, dynamic> heartRiskData({
    required double heartRate,
    required double bloodSugar,
    required double height,
    required double weight,
    required double cholesterol,
    required int smoking,
    required int alcohol,
    required double bmi,
  }) {
    return {
      'heart_rate': heartRate,
      'blood_sugar': bloodSugar,
      'height': height,
      'weight': weight,
      'cholesterol': cholesterol,
      'smoking': smoking,
      'alcohol': alcohol,
      'activity_level': 1, // Always set to 1 as requested
      'bmi': bmi,
    };
  }

  Future<Map<String, dynamic>> getPainHistory(String userId ,String timeRange) async {

    try {
      final response = await dio.get(
        '/get_pain_history/$userId',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        print(response.data);
        return response.data;
      } else {
        throw Exception('Failed to fetch pain history');
      }
    } catch (e) {
      throw Exception('Error fetching pain history: $e');
    }
  }


  Future<String> predictHeartRiskViaLocation({
    required int heartRate,
    required int painDurationMinutes,
    required String activityType,
    required String painLocation,
    required String accompanyingSymptoms,
    required String userID,
  }) async {
    try {
      Response response = await dio.post(
        '/predict_heart_risk',
        queryParameters: {'user_id': userID},
        data: {
          'heart_rate': heartRate,
          'pain_duration_minutes': painDurationMinutes,
          'activity_type': activityType,
          'pain_location': painLocation,
          'accompanying_symptoms': accompanyingSymptoms,
        },
      );

      if (response.statusCode == 200) {
        return response.data['predicted_risk_level'];
      } else {
        throw Exception('Failed to predict heart risk');
      }
    } catch (e) {
      throw Exception('Error predicting heart risk: $e');
    }
  }

  Future<Map<String, dynamic>> predictHeartRisk({
    required double heartRate,
    required double bloodSugar,
    required double height,
    required double weight,
    required double cholesterol,
    required bool smoking,
    required bool alcohol,
    required double bmi,
    required String userId,
  }) async {
    try {
      var heartRiskRequestData = heartRiskData(
        heartRate: heartRate,
        bloodSugar: bloodSugar,
        height: height,
        weight: weight,
        cholesterol: cholesterol,
        smoking: smoking ? 1 : 0,
        alcohol: alcohol ? 1 : 0,
        bmi: bmi,
      );

      print('Sending heart risk data: $heartRiskRequestData');

      Response response = await dio.post(
        '/predict_risk',
        data: heartRiskRequestData,
        queryParameters: {'user_id': userId},
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        print('Heart risk prediction response: ${response.data}');
        return {
          'status': 'success',
          'risk_level': response.data['risk_level'],
          'risk_probability': response.data['risk_probability'],
          'bmi_category': response.data['bmi_category'],
          'health_score': response.data['health_score'],
          'recommendations': List<String>.from(response.data['recommendations']),
          'timestamp': response.data['timestamp'],
        };
      } else {
        return {'status': 'error', 'message': 'Failed to predict heart risk'};
      }
    } catch (e) {
      print('Error predicting heart risk: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }


  Future<List<Map<String, dynamic>>> getHealthRecords(
      String userId, String period) async {
    try {
      Response response = await dio.get(
        '/health-records/$userId/$period',
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> records = List<Map<String, dynamic>>.from(
            response.data['records']
                .map((record) => Map<String, dynamic>.from(record)));
        return records;
      } else {
        throw Exception('Failed to fetch health records');
      }
    } catch (e) {
      print('Error fetching health records: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getLatestHealthRecord(String userId) async {
    print("userId $userId");
    try {
      Response response = await dio.get(
        '/latest-health-records/$userId/latest',  // New endpoint
      );

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'health_score': response.data['health_score'],
          'risk_level': response.data['risk_level'],
          'risk_probability': response.data['risk_probability'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to fetch latest health record'
        };
      }
    } catch (e) {
      print('Error fetching latest health record: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }


  Future<Map<String, dynamic>> uploadECGReport(File imageFile, String userId) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      Response response = await dio.post(
        '/upload-ecg/$userId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Status: ${response.data['status']}');


      if (response.statusCode == 200 && response.data['status'] == "success") {
        // Parse questions and answers
        List<QuestionsAndAnswers> qaList = [];
        if (response.data['questions_and_answers'] != null) {
          qaList = List<QuestionsAndAnswers>.from(
            response.data['questions_and_answers'].map(
                  (qa) => QuestionsAndAnswers.fromJson(qa),
            ),
          );
        }

        return {
          'status': 'success',
          'message': response.data['message'],
          'questions_and_answers': qaList,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to upload ECG report || Uploaded image does not appear to be an ECG',
        };
      }
    } catch (e) {
      print('Error uploading ECG report: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // In your apiDio class
  Future<Map<String, dynamic>> predictEmotionViaCamera(File imageFile) async {
    try {
      // Create form data
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Make API call
      Response response = await dio2.post(
        '/predict-emotion-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        print(response);
        if (response.data['status'] == 'success') {
          return {
            'status': 'success',
            'emotion': response.data['emotion'],
            'message': response.data['message'],
          };
        }else{
          return {
            'status': 'error',
            'message': 'Failed to detect emotion',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to detect emotion',
        };
      }
    } catch (e) {
      print('Error predicting emotion from image: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<bool> sendNotification(String userId, String type, {String? emotion}) async {
    try {
      final response = await dio.post(
        '/notifications/send',
        data: {
          "userID": userId,
          "type": type,
          if (emotion != null) "emotion": emotion,  // Include emotion only if type is "emotion"
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully");
        return true;
      } else {
        print("Failed to send notification: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error sending notification: $e");
      return false;
    }
  }

  // Get user's health metrics (heart rate, height, weight)
  Future<Map<String, dynamic>> getHealthMetrics(BuildContext context) async {
    try {
      // Get user ID from SharedPreferences
      await _initPrefs();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('User is not logged in');
      }

      // Make API request
      final response = await dio.get(
        '/metrics/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load health metrics');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load health metrics';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(errorMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> getUserHealthRecords(BuildContext context, {int limit = 10}) async {
    try {
      // Get user ID from SharedPreferences
      await _initPrefs();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('User is not logged in');
      }

      // Make API request
      final response = await dio.get(
        '/health_records/$userId',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['records'] as List<dynamic>;
      } else {
        throw Exception('Failed to load health records');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load health records';

      if (e.response?.data != null && e.response?.data['detail'] != null) {
        errorMessage = e.response?.data['detail'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(errorMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      throw Exception(e.toString());
    }
  }

}
