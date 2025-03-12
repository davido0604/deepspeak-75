import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
// import 'screens/recordings_history_screen.dart'; // Commented out
import 'screens/settings_screen.dart';
import 'screens/upload_file_screen.dart';
import 'screens/recording_screen.dart'; // The new unified screen

// Custom PageTransitionsBuilder that disables transitions.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deepspeak Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionsBuilder(),
            TargetPlatform.fuchsia: NoTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(), // This is your initial route
      routes: {
        '/recording': (context) => const RecordingScreen(),
        // '/history': (context) => const RecordingsHistoryScreen(),
        '/upload': (context) => const UploadFileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
