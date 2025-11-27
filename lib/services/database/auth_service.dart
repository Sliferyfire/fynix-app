import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:fynix/services/database/tasks_service.dart';
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late OfflineTasksService offlineTasksService;

  void onLogin(BuildContext context) {
    // final tasksService = Provider.of<TasksService>(context, listen: false);
    final offlineTasksService = Provider.of<OfflineTasksService>(
      context,
      listen: false,
    );

    offlineTasksService.loadLocal();
    offlineTasksService.obtenerTasksDia(DateTime.now());
  }

  Future<AuthResponse?> signUpNewUser(
    String email,
    String password,
    String username,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {"username": username},
      );
      final user = response.user;
      if (user == null || user.identities?.isEmpty == true) {
        throw AuthException(
          "Este correo ya se encuentra registrado. Intenta iniciar sesión.",
        );
      }
      return response;
    } on AuthApiException catch (e) {
      if (e.code == "user_already_exists") {
        throw AuthException(
          "Este correo ya se encuentra registrado. Intenta iniciar sesión.",
        );
      } else if (e.code == "invalid_email") {
        throw AuthException("El formato del correo electrónico no es válido.");
      } else if (e.code == "weak_password") {
        throw AuthException("La contraseña es demasiado debil.");
      } else {
        throw AuthException("Ocurrio un error al registrar al usuario.");
      }
    } on AuthException catch (e) {
      debugPrint("AuthException: $e");
      rethrow;
    } on SocketException {
      throw AuthException("No hay conexión a internet. Intenta de nuevo.");
    } catch (e) {
      debugPrint("Error inesperado: $e");
      throw AuthException("Error inesperado. Intenta mas tarde.");
    }
  }

  Future<AuthResponse?> signInUser(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user == null) {
        throw AuthException(
          "No se pudo iniciar sesion. Verifica tus credenciales.",
        );
      }
      if (user.emailConfirmedAt == null) {
        throw AuthException(
          "Tu correo aún no ha sido confirmado. Confirma tu correo antes de iniciar sesion.",
        );
      }

      return response;
    } on AuthApiException catch (e) {
      if (e.code == 'email_not_confirmed') {
        throw AuthException(
          "Tu correo aún no ha sido confirmado. Revisa tu bandeja de entrada.",
        );
      } else if (e.code == 'invalid_credentials') {
        throw AuthException("Correo o contraseña incorrectos.");
      } else {
        throw AuthException(e.message);
      }
    } on AuthException catch (e) {
      debugPrint("AuthException: $e");
      rethrow;
    } on SocketException {
      throw AuthException("No hay conexión a internet. Intenta de nuevo.");
    } catch (e) {
      debugPrint('Error inesperado: $e');
      throw AuthException('Ocurrió un error inesperado. Intenta más tarde.');
    }
  }

  String? _getOAuthRedirectUrl() {
    if (kIsWeb) {
      return null;
    }
    return "fynix://login-callback";
  }

  Future<bool> googleSignIn() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getOAuthRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        throw AuthException("Error: No se pudo iniciar el flujo de OAuth");
      }

      return true;
    } catch (e) {
      throw AuthException("Error en googleSignIn: $e");
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
