import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fynix/providers/auth_form_provider.dart';
import 'package:fynix/services/auth_service.dart';
import 'package:fynix/widgets/card_container.dart';
import 'package:fynix/widgets/fondo_login.dart';
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final loginForm = Provider.of<AuthProvider>(context);

    return SizedBox(
      child: Form(
        key: loginForm.formKey,
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
              onChanged: (value) => {loginForm.email = value},
              validator: (value) {
                String pattern =
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                RegExp regExp = new RegExp(pattern);
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
              onChanged: (value) => {loginForm.password = value},
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
                  loginForm.isLoading
                      ? null
                      : () async {
                        FocusScope.of(context).unfocus();
                        if (!loginForm.isValidForm()) return;
                        loginForm.isLoading = true;
                        authService.signInUser(
                          loginForm.email,
                          loginForm.password,
                        );
                        loginForm.isLoading = false;
                        Navigator.pushReplacementNamed(context, "home");
                      },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                child: Text(
                  "Login",
                  style: GoogleFonts.lilitaOne(
                    color: Color(0x88000000),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            _LoginFooter(),
            SizedBox(height: 30,),
            MaterialButton(
              minWidth: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              disabledColor: Colors.grey,
              elevation: 0,
              color: Color(0xFFC8D3D4),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "home");
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                child: Text(
                  "Boton temporal por si no sirve el login.",
                  style: GoogleFonts.lilitaOne(
                    color: Color(0x88000000),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  // const _LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  thickness: 3,
                  height: 0,
                  color: Color(0x88000000),
                ),
              ),
            ),
            Text(
              "OR",
              style: GoogleFonts.lilitaOne(
                color: Color(0x88000000), 
                fontSize: 18
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  thickness: 3,
                  height: 0,
                  color: Color(0x88000000),
                ),
              ),
            ),
          ],
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xff6F9698),
              backgroundImage: AssetImage("assets/google_logo.png"),
            ),
          ),
        ),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "¿No tienes una cuenta? ",
              style: GoogleFonts.lilitaOne(color: Color(0x88000000), fontSize: 18),
              children: [
                TextSpan(
                  text: " Registrate",
                  style: GoogleFonts.lilitaOne(
                    color: Color(0x88000000),
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, 'register');
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


