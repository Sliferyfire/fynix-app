import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fynix/controllers/auth_controller.dart';
import 'package:fynix/providers/auth_form_provider.dart';
import 'package:fynix/widgets/auth/auth_card_container.dart';
import 'package:fynix/widgets/auth/auth_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

  final Color _textColor = Color(0x88000000);
  final Color _backInputColor = Color(0xFFC8D3D4);

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
              style: GoogleFonts.lilitaOne(color: _textColor, fontSize: 20),
              autocorrect: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: _backInputColor,
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
                  color: _textColor,
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
              style: GoogleFonts.lilitaOne(color: _textColor, fontSize: 20),
              autocorrect: true,
              obscureText: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: _backInputColor,
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
                  color: _textColor,
                  fontSize: 20,
                ),
              ),
              onChanged: (value) => {authForm.password = value},
              validator: (value) {
                if (value != null && value.length >= 8) {
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
              color: _backInputColor,
              onPressed:
                  authForm.isLoading
                      ? null
                      : () => context.read<AuthController>().handleSignIn(
                        context,
                        authForm,
                      ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                child: Text(
                  "Login",
                  style: GoogleFonts.lilitaOne(
                    color: _textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            _LoginFooter(),
          ],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  // const _LoginFooter({super.key});
  final Color _textColor = Color(0x88000000);

  @override
  Widget build(BuildContext context) {
    // final authService = Provider.of<AuthService>(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(thickness: 3, height: 0, color: _textColor),
              ),
            ),
            Text(
              "OR",
              style: GoogleFonts.lilitaOne(color: _textColor, fontSize: 18),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(thickness: 3, height: 0, color: _textColor),
              ),
            ),
          ],
        ),
        SizedBox(height: 15,),
        Center(
          child: GestureDetector(
            onTap: () => context.read<AuthController>().handleGoogleSignIn(context), 
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xff6F9698),
              backgroundImage: AssetImage("assets/google_logo.png"),
            ),
          ),
        ),
        SizedBox(height: 15,),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "¿No tienes una cuenta? ",
              style: GoogleFonts.lilitaOne(color: _textColor, fontSize: 18),
              children: [
                TextSpan(
                  text: " Registrate",
                  style: GoogleFonts.lilitaOne(
                    color: _textColor,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, '/register');
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
