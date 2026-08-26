import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/screens/home_screen.dart';

import 'ui/widgets/translation_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('app_state');
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wnovel Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (context) => child!),
            OverlayEntry(
              builder: (context) => const Directionality(
                textDirection: TextDirection.ltr,
                child: TranslationOverlayWidget(),
              ),
            ),
          ],
        );
      },
      home: const HomeScreen(),
    );
  }
}
