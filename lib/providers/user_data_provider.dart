import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;

  UserDataProvider() {
    _supabase.auth.onAuthStateChange.listen((event) {
      _user = _supabase.auth.currentUser;
      notifyListeners();
    });
    _user = _supabase.auth.currentUser;
  }

  User? get user => _user; 

  String? get userId => _user?.id;
  // String? get token => _user?.appMetadata['provider_token'];
  String? get username => _user?.appMetadata['username'];
}
