import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/contact_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Pour émulateur Android
  // Pour mobile physique ou iOS simulator : remplace par l'IP de ton PC, ex: 'http://192.168.1.35:8000'

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
static Future<bool> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  print('Login status: ${response.statusCode}');
  print('Login body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['access_token'];
    print('Token reçu : $token');  // ← Debug
    await saveToken(token);
    return true;
  }
  return false;
}

  // Register
  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return true;
    }
    return false;
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }

  // Get all contacts
  static Future<List<Contact>> getContacts() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/contacts'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contact.fromMap(json)).toList();
    }
    return [];
  }

  // Search contacts
  static Future<List<Contact>> searchContacts(String query) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/search?q=$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contact.fromMap(json)).toList();
    }
    return [];
  }

  // Add contact with optional photo
  static Future<bool> addContact(Contact contact, File? photoFile) async {
  try {
    final headers = await getHeaders();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/contacts'));
    request.headers.addAll(headers);
    request.fields['name'] = contact.name;
    request.fields['email'] = contact.email;
    request.fields['phone'] = contact.phone;

    if (photoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
    }

    final response = await request.send();

    print('Status code ajout contact : ${response.statusCode}');  // ← Log

    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = await response.stream.bytesToString();
      print('Erreur ajout contact : $responseBody');  // ← Log l'erreur du serveur
      return false;
    }
  } catch (e) {
    print('Exception lors de l\'ajout : $e');  // ← Log exception réseau
    return false;
  }
}
  // Update contact with optional photo
  static Future<bool> updateContact(Contact contact, File? photoFile) async {
    final headers = await getHeaders();
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/contacts/${contact.id}'));
    request.headers.addAll(headers);
    request.fields['name'] = contact.name;
    request.fields['email'] = contact.email;
    request.fields['phone'] = contact.phone;

    if (contact.photoUrl != null && contact.photoUrl!.startsWith('/uploads')) {
      request.fields['photoUrl'] = contact.photoUrl!; // Ancienne URL si pas de nouvelle photo
    }

    if (photoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // Delete contact
  static Future<bool> deleteContact(String contactId) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/contacts/$contactId'),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}