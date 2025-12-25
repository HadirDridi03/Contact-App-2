import 'package:flutter/material.dart';
import 'contact_controller.dart';

class HomeController {
  final ContactController contactController;
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');//Un notificateur d'état qui contient la requête de recherche
  // Les widgets qui l'écoutent se reconstruiront quand sa valeur changera

  HomeController({required this.contactController}) {//constructeur qui requit contactController
    searchController.addListener(() {// fonction appelée à chaque fois que l'utilisateur tape ou efface un caractère dans le champ de recherche.
      searchQuery.value = searchController.text.trim();// Met à jour la valeur du ValueNotifier avec le texte actuel du champ de recherche
    });
  }
  // Libère les ressources des contrôleurs pour éviter les fuites de mémoire
  void dispose() {
    searchController.dispose();
    searchQuery.dispose();
  }
}