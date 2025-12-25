import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/home/add_contact_view.dart';
import '../views/home/edit_contact_view.dart';
import '../model/contact_model.dart';
import '../service/api_service.dart';  // ← Nouveau

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final token = await ApiService.getToken();
    final bool isLoggedIn = token != null;
    final String location = state.uri.path;

    // Pas connecté → force login
    if (!isLoggedIn && location != '/login' && location != '/register') {
      return '/login';
    }

    // Connecté mais sur login/register → renvoie à home
    if (isLoggedIn && (location == '/login' || location == '/register')) {
      return '/';
    }

    // Sinon, laisse passer
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddContactView(),
    ),
    GoRoute(
      path: '/edit',
      builder: (context, state) {
        final contact = state.extra as Contact?;
        if (contact == null) {
          return const HomeView();
        }
        return EditContactView(contact: contact);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page non trouvée : ${state.uri}',
        style: const TextStyle(fontSize: 18, color: Colors.red),
      ),
    ),
  ),
);