import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fynix/controllers/auth_controller.dart';
import 'package:fynix/providers/auth_form_provider.dart';
// import 'package:fynix/services/auth_service.dart';
import 'package:fynix/widgets/card_container.dart';
import 'package:fynix/widgets/fondo_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoLogin(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 200),
              CardContainer(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Bienvenidos',
                      style: GoogleFonts.lilitaOne(
                        color: Color(0x88000000),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ChangeNotifierProvider(
                      create: (context) => AuthProvider(),
                      child: _LoginForm(),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  // const _LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    // final authService = Provider.of<AuthService>(context);
    final authForm = Provider.of<AuthProvider>(context);

    return SizedBox(
      child: Form(
        key: authForm.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              textAlign: TextAlign.center,
              style: GoogleFonts.lilitaOne(
                color: Color(0x88000000),
                fontSize: 20,
              ),
              autocorrect: true,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFC8D3D4),
                contentPadding: EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                hintText: "Nombre de usuario",
                hintStyle: GoogleFonts.lilitaOne(
                  color: Color(0x88000000),
                  fontSize: 20,
                ),
              ),
              onChanged: (value) => {authForm.username = value},
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return null;
                } else {
                  return "Nombre de usuario obligatorio.";
                }
              }, // Validator
            ),
            SizedBox(height: 30),
            TextFormField(
              textAlign: TextAlign.center,
              style: GoogleFonts.lilitaOne(
                color: Color(0x88000000),
                fontSize: 20,
              ),
              autocorrect: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFC8D3D4),
                contentPadding: EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                hintText: "Email",
                hintStyle: GoogleFonts.lilitaOne(
                  color: Color(0x88000000),
                  fontSize: 20,
                ),
              ),
              onChanged: (value) => {authForm.email = value},
              validator: (value) {
                String pattern =
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                RegExp regExp = RegExp(pattern);
                return regExp.hasMatch(value ?? '')
                    ? null
                    : "El correo no es valido.";
              }, // Validator
            ),
            SizedBox(height: 30),
            TextFormField(
              textAlign: TextAlign.center,
              style: GoogleFonts.lilitaOne(
                color: Color(0x88000000),
                fontSize: 20,
              ),
              autocorrect: true,
              obscureText: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFC8D3D4),
                contentPadding: EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                hintText: "Password",
                hintStyle: GoogleFonts.lilitaOne(
                  color: Color(0x88000000),
                  fontSize: 20,
                ),
              ),
              onChanged: (value) => {authForm.password = value},
              validator: (value) {
                if (value != null && value.length >= 6) {
                  return null;
                } else {
                  return "Contraseña de al menos 8 caracteres.";
                }
              }, // Validator
            ),
            SizedBox(height: 30),
            MaterialButton(
              minWidth: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              disabledColor: Colors.grey,
              elevation: 0,
              color: Color(0xFFC8D3D4),
              onPressed:
                  authForm.isLoading
                      ? null
                      : () => context.read<AuthController>().handleSignUp(context, authForm),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                child: Text(
                  "Register",
                  style: GoogleFonts.lilitaOne(
                    color: Color(0x88000000),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            _RegisterFooter(),
          ],
        ),
      ),
    );
  }
}

class _RegisterFooter extends StatelessWidget {
  // const _RegisterFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: "¿Ya tienes una cuenta? ",
          style: GoogleFonts.lilitaOne(color: Color(0x88000000), fontSize: 18),
          children: [
            TextSpan(
              text: " Inicia Sesion",
              style: GoogleFonts.lilitaOne(
                color: Color(0x88000000),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.pushNamed(context, 'login');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
