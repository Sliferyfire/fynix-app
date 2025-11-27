import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fynix/controllers/auth_controller.dart';
import 'package:fynix/providers/user_data_provider.dart';
import 'package:fynix/screens/almacen_screen.dart';
import 'package:fynix/screens/finanzas_screen.dart';
import 'package:fynix/screens/home_screen.dart';
import 'package:fynix/screens/login_screen.dart';
import 'package:fynix/screens/personal_screen.dart';
import 'package:fynix/screens/proveedores_screen.dart';
import 'package:fynix/screens/register_screen.dart';
import 'package:fynix/services/database/auth_service.dart';
import 'package:fynix/services/database/tasks_service.dart';
import 'package:fynix/services/offline/offline_tasks_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // await dotenv.load(fileName: ".env");

  // await Supabase.initialize(
  //   url: dotenv.env["SUPABASE_URL"]!,
  //   anonKey: dotenv.env["SUPABASE_ANON_KEY"]!,
  //   authOptions: const FlutterAuthClientOptions(
  //     authFlowType: AuthFlowType.pkce,
  //   ),
  // );

  await Supabase.initialize(
    url: const String.fromEnvironment("SUPABASE_URL"),
    anonKey: const String.fromEnvironment("SUPABASE_ANON_KEY"),
  );

  runApp(_AppState());
}

class _AppState extends StatelessWidget {
  // const _AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => TasksService()),
        ChangeNotifierProvider(create: (_) => OfflineTasksService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return ChangeNotifierProvider<AuthController>(
            create: (_) => AuthController(authService),
            child: const MainApp(),
          );
        },
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    Future<void> _setFcmToken(String fcmToken) async {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('PROFILES').upsert({
          'id': userId,
          'fcm_token': fcmToken,
        });
      }
    }

    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission;
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await _setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title} ${notification.body}')),
        );
      }
    });

    // Escuchar el evento de login real
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      context.read<AuthService>().onLogin(context);

      if (session != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          "/home",
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Fynix",
      home: AuthGate(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => HomeScreen(),
        '/finanzas': (_) => const FinanzasScreen(),
        '/proveedores': (_) => const ProveedoresScreen(),
        '/personal': (_) => const PersonalScreen(),
        '/almacen': (_) => const AlmacenScreen(),
      },
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Color(0xFF84B9BF),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF84B9BF),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserDataProvider>().setUser(session.user);
      });
      return const HomeScreen();
    }

    final user = context.watch<UserDataProvider>().user;
    if (user != null) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
