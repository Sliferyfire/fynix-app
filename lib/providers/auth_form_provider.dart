import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String username = '';
  String email = '';
  String password = '';

  bool _isloading = false;
  bool get isLoading => _isloading;

  set isLoading(bool value) {
    _isloading = value;
    notifyListeners();
  }

  bool isValidForm() {
    return formKey.currentState?.validate() ?? false;
  }
}
