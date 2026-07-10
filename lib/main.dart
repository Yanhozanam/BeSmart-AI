import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/model_provider.dart';
import 'services/cache_manager.dart';
import 'services/model_manager.dart';
import 'services/storage_service.dart';
import 'screens/chat_screen.dart';
import 'screens/download_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  await CacheManager().cleanOnStartup();

  await ModelManager().initialize();

  runApp(const BeSmartAIApp());
}

class BeSmartAIApp extends StatelessWidget {
  const BeSmartAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
      ],
      child: MaterialApp(
        title: 'BeSmartAI',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AppEntry(),
      ),
    );
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
