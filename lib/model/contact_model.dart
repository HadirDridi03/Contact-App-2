import 'package:uuid/uuid.dart';

class Contact {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl; // ← Changé : URL distante maintenant

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photo_url'] as String?,
    );
  }

  factory Contact.createNew({
    required String name,
    required String email,
    required String phone,
    String? photoUrl,
  }) {
    return Contact(
      id: '',
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}