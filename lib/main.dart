import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teatcher_smarter/app_themes/app_theme.dart';
import 'package:teatcher_smarter/models/letter_model.dart';
import 'package:teatcher_smarter/models/math_model.dart';
import 'package:teatcher_smarter/models/math_teaching_model.dart';
import 'package:teatcher_smarter/models/number_model.dart';
import 'package:teatcher_smarter/providers/letter_provider.dart';
import 'package:teatcher_smarter/providers/math_provider.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';
import 'package:teatcher_smarter/services/api_sentens_service.dart';
import 'package:teatcher_smarter/services/api_service.dart';
import 'models/level_ar.dart';
import 'providers/sentence_progress_provider.dart';
import 'providers/sentence_provider.dart';
import 'providers/user_progress_provider.dart';
import 'providers/word_progress_provider.dart';
import 'screens/main_menu.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => SentenceProvider(
                apiService: ApiSentensService(
                    'http://192.168.187.171:5077/api/Sentences'))),
        ChangeNotifierProvider(
            create: (_) => WordsProvider(
                apiService: ApiService(
                    baseUrl: 'http://192.168.187.171:5077/api/Words'))),
        ChangeNotifierProvider(create: (_) => LetterModel1()),
        ChangeNotifierProvider(create: (_) => NumberModel()),
        ChangeNotifierProvider(create: (_) => MathModel()),
        ChangeNotifierProvider(create: (_) => MathTeachingModel()),
        ChangeNotifierProvider(create: (_) => LetterProvider()),
        ChangeNotifierProvider(create: (_) => LetterModel()),
        ChangeNotifierProvider(
          create: (context) => MathProvider(
            baseUrl: 'http://192.168.187.171:5077/api/MathExamples',
          ),
        ),
        ChangeNotifierProvider(create: (_) => UserProgressProvider()),
        ChangeNotifierProvider(create: (_) => WordProgressProvider()),
        ChangeNotifierProvider(create: (_) => SentenceProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعلم الحساب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      locale: const Locale('ar', 'SA'),
      home: MainMenu(),
    );
  }
}
