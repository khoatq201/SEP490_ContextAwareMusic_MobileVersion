import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'injection_container.dart';
import 'router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/mqtt_service.dart';
import 'core/presentation/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize dependency injection
    await initializeDependencies();

    // Initialize local storage
    final localStorage = sl<LocalStorageService>();
    await localStorage.init();

    // Initialize MQTT connection
    final mqttService = sl<MqttService>();
    try {
      await mqttService.connect(
        clientId: 'cams_manager_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('MQTT connection failed: $e');
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(
          onInitializationComplete: _initializeApp,
        ),
      );
    }

    return MaterialApp.router(
      title: 'CAMS Store Manager',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
