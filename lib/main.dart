import 'package:flutter/material.dart';
import 'package:air_mind/screens/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:air_mind/screens/spalsh.dart';
import 'package:air_mind/screens/chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:air_mind/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Whisper AI',
      theme: ThemeData().copyWith(
          colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 28, 133, 151),
      )),
      home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen();
            }
            if (snapshot.hasData) {
              return ChatScreen();
            }
            return AuthScreen();
          }),
    );
  }
}
