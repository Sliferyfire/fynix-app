import 'package:flutter/material.dart';
import 'package:fynix/providers/auth_form_provider.dart';
import 'package:fynix/services/database/auth_service.dart';
import 'package:fynix/widgets/auth/auth_custom_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService;
  // final Color _textColor = Color(0x88000000);
  final TextStyle _textStyle = GoogleFonts.lilitaOne(
    fontSize: 20,
    color: Color(0x88000000),
  );

  AuthController(this._authService);

  Future<void> handleSignUp(BuildContext context, AuthProvider authForm) async {
    FocusScope.of(context).unfocus();
    if (!authForm.isValidForm()) return;
    authForm.isLoading = true;

    try {
      final response = await _authService.signUpNewUser(
        authForm.email,
        authForm.password,
        authForm.username,
      );
      if (response != null) {
        await showDialog(
          context: context,
          builder:
              (context) => CustomModal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Usuario registrado correctamente.",
                      style: _textStyle,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Confirma tu registro en tu correo electronico.",
                      style: _textStyle,
                    ),
                    SizedBox(height: 20),
                    _AcceptButton(textStyle: _textStyle),
                  ],
                ),
              ),
        );
      } 
    } on AuthException catch (e) {
      await showDialog(
        context: context,
        builder:
            (context) => CustomModal(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.message, style: _textStyle),
                  SizedBox(height: 20),
                  _AcceptButton(textStyle: _textStyle),
                ],
              ),
            ),
      );
    } finally {
      authForm.isLoading = false;
    }
  }

  Future<void> handleSignIn(BuildContext context, AuthProvider authForm) async {
    FocusScope.of(context).unfocus();
    if (!authForm.isValidForm()) return;
    authForm.isLoading = true;

    try {
      final response = await _authService.signInUser(
        authForm.email,
        authForm.password,
      );
      if (response?.user != null) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } on AuthException catch (e) {
      await showDialog(
        context: context,
        builder:
            (context) => CustomModal(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.message, style: _textStyle),
                  SizedBox(height: 20),
                  _AcceptButton(textStyle: _textStyle),
                ],
              ),
            ),
      );
    } finally {
      authForm.isLoading = false;
    }
  }

  Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      await _authService.googleSignIn(); 
    } on AuthException catch(e) {
      await showDialog(
        context: context,
        builder:
            (context) => CustomModal(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.message, style: _textStyle),
                  SizedBox(height: 20),
                  _AcceptButton(textStyle: _textStyle),
                ],
              ),
            ),
      );
    }
  }
}

class _AcceptButton extends StatelessWidget {
  final TextStyle textStyle;

  const _AcceptButton({required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text("Aceptar", style: textStyle),
    );
  }
}
