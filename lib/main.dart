import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'providers/model_provider.dart';
import 'services/cache_manager.dart';
import 'services/model_manager.dart';
import 'services/storage_service.dart';
import 'screens/chat_screen.dart';
import 'screens/download_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  await CacheManager().cleanOnStartup();

  await DebugLogger().init();

  await ModelManager().initialize();

  runApp(const BeSmartAIApp());
}

class BeSmartAIApp extends StatelessWidget {
  const BeSmartAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    storage.init();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
      ],
      child: ValueListenableBuilder<String>(
        valueListenable: _LanguageNotifier(storage),
        builder: (context, localeStr, _) {
          return MaterialApp(
            title: 'BeSmart',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
            ],
            locale: Locale(localeStr),
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

class _LanguageNotifier extends ValueNotifier<String> {
  _LanguageNotifier(StorageService storage) : super(storage.getLanguage()) {
    _listenForChanges(storage);
  }

  Future<void> _listenForChanges(StorageService storage) async {
    // This is a simple polling approach - in a real app you might use a stream
    // For now, we just set the initial value
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final onboardingDone = storage.getOnboardingDone();

    if (!onboardingDone) {
      return const OnboardingScreen();
    }

    final modelReady = ModelManager().isReady;
    if (modelReady) {
      return const ChatScreen();
    }
    return const DownloadScreen();
  }
}
