import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signInUser(String email, String password) async {
    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    print(user?.userMetadata?["username"]);
    print(response.user);
  }

  Future<void> signUpNewUser(
    String email,
    String password,
    String username,
  ) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {"username": username},
    );
    print(response.user);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
