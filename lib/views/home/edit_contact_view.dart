import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/contact_controller.dart';
import '../../model/contact_model.dart';

class EditContactView extends StatefulWidget {
  final Contact contact;
  const EditContactView({super.key, required this.contact});

  @override
  State<EditContactView> createState() => _EditContactViewState();
}

class _EditContactViewState extends State<EditContactView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final ContactController _controller = ContactController();

  File? _photoFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _emailController = TextEditingController(text: widget.contact.email);
    _phoneController = TextEditingController(text: widget.contact.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _updateContact() async {
    final updatedContact = widget.contact.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    setState(() => _isLoading = true);

    final success = await _controller.saveContact(updatedContact, _photoFile);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact modifié avec succès !")),
      );
      context.go('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la modification")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le contact"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: ClipOval(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _photoFile != null
                        ? Image.file(_photoFile!, fit: BoxFit.cover)
                        : widget.contact.photoUrl != null
                            ? Image.network(
                                'http://10.0.2.2:8000${widget.contact.photoUrl!}', // Même baseUrl que dans home
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFFFF3E0),
                                  child: Center(
                                    child: Text(
                                      widget.contact.name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.brown),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFFFF3E0),
                                child: Center(
                                  child: Text(
                                    widget.contact.name.isNotEmpty ? widget.contact.name[0].toUpperCase() : "+",
                                    style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.brown),
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom complet"),
                validator: (v) => v?.trim().isEmpty ?? true ? "Nom obligatoire" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.trim().isEmpty ?? true ? "Email obligatoire" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Téléphone"),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Téléphone obligatoire";
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  return RegExp(r'^216?[2579]\d{7}$').hasMatch(cleaned) ? null : "Numéro invalide";
                },
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateContact,
                      child: const Text("Mettre à jour"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}