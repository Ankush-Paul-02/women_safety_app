import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:women_safety_app/presentation/home/screens/home_screen.dart';
import 'package:women_safety_app/presentation/home/viewmodels/home_state_provider.dart';

import 'core/di/service_locator.dart';
import 'firebase_options.dart';
import 'presentation/auth/screens/phone_auth_screen.dart';
import 'presentation/auth/viewmodels/auth_state_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterContacts.config.enableIosNotes = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initServiceLocator();

  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStateProvider>(
          create: (_) => sl<AuthStateProvider>(),
        ),
        ChangeNotifierProvider<HomeStateProvider>(
          create: (_) => sl<HomeStateProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'Women Safety',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0071E3),
            surface: const Color(0xFFF5F5F7),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();

    if (auth.currentUser != null) {
      return const HomeScreen();
    }

    return const PhoneAuthScreen();
  }
}
