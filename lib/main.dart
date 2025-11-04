import 'package:flutter/material.dart';
import 'package:fynix/providers/user_data_provider.dart';
import 'package:fynix/screens/almacen_screen.dart';
import 'package:fynix/screens/finanzas_screen.dart';
import 'package:fynix/screens/home_screen.dart';
import 'package:fynix/screens/login_screen.dart';
import 'package:fynix/screens/personal_screen.dart';
import 'package:fynix/screens/proveedores_screen.dart';
import 'package:fynix/screens/register_screen.dart';
import 'package:fynix/screens/reportes_screen.dart';
import 'package:fynix/services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // await dotenv.load(fileName: ".env");
  // await Supabase.initialize(
  //   url: dotenv.env["SUPABASE_URL"]!,
  //   anonKey: dotenv.env["SUPABASE_ANON_KEY"]!,
  // );

  await Supabase.initialize(
    url: const String.fromEnvironment("SUPABASE_URL"),
    anonKey: const String.fromEnvironment("SUPABASE_ANON_KEY"),
  );

  runApp(AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          
        ),
        ChangeNotifierProvider(
          create: (_) => UserDataProvider(),
        )
      ],
      child: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Fynix",
      initialRoute: "login",
      routes: {
        'login': (_) => LoginScreen(),
        'register': (_) => RegisterScreen(),
        'home': (_) => HomeScreen(),
        'finanzas': (context) => const FinanzasScreen(),
        'proveedores': (context) => const ProveedoresScreen(),
        'personal': (context) => const PersonalScreen(),
        'reportes': (context) => const ReportesScreen(),
        'almacen': (context) => const AlmacenScreen(),
      },
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Color(0xFF84B9BF),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF84B9BF),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
