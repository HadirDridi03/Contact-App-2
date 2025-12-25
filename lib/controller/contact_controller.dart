import 'dart:io';
import '../../model/contact_model.dart';
import '../../service/api_service.dart';

class ContactController {
  Future<List<Contact>> getContacts() async {
    return await ApiService.getContacts();
  }

  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return await getContacts();
    return await ApiService.searchContacts(query);
  }

  Future<bool> saveContact(Contact contact, File? photoFile) async {
    if (contact.id.isEmpty || contact.id == 'new') {
      // Ajout
      return await ApiService.addContact(contact, photoFile);
    } else {
      // Modification
      return await ApiService.updateContact(contact, photoFile);
    }
  }

  Future<bool> deleteContact(String contactId) async {
    return await ApiService.deleteContact(contactId);
  }
}