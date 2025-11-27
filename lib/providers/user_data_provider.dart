import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;

  UserDataProvider() {
    _supabase.auth.onAuthStateChange.listen((event) {
      _user = _supabase.auth.currentUser;
      print("------------------------");
      print(_user);
      print("------------------------");
      notifyListeners();
    });
    _user = _supabase.auth.currentUser;
  }

  User? get user => _user;

  String? get userId => _user?.id;
  // String? get token => _user?.appMetadata['provider_token'];
  String? get username =>
    _user?.userMetadata?['username'] ??
    _user?.userMetadata?['full_name'] ??
    _user?.userMetadata?['name'];

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  String? get photoUrl => _user?.userMetadata?['picture'];
}
