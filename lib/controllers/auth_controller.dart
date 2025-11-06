import 'package:flutter/material.dart';
import 'package:fynix/providers/auth_form_provider.dart';
import 'package:fynix/services/auth_service.dart';
import 'package:fynix/widgets/custom_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService;
  final Color _textColor = Color(0x88000000);

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
      if (response != null && response.user != null) {
        await showDialog(
          context: context,
          builder:
              (context) => CustomModal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Usuario registrado correctamente.",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 20,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Confirma tu registro en tu correo electronico.",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 20,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Aceptar",
                        style: GoogleFonts.lilitaOne(
                          fontSize: 20,
                          color: _textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
      } else {
        await showDialog(
          context: context,
          builder:
              (context) => CustomModal(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Error, la respuesta de autenticacion fue inesperada.",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 20,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Aceptar",
                        style: GoogleFonts.lilitaOne(
                          fontSize: 20,
                          color: _textColor,
                        ),
                      ),
                    ),
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
                  Text(
                    "Error de autenticacion: $e",
                    style: GoogleFonts.lilitaOne(
                      fontSize: 20,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Aceptar",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 20,
                        color: _textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder:
            (context) => CustomModal(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Error inesperado. Por favor intente de nuevo.",
                    style: GoogleFonts.lilitaOne(
                      fontSize: 20,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Aceptar",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 20,
                          color: _textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    } finally {
      authForm.isLoading = false;
    }
  }
}
