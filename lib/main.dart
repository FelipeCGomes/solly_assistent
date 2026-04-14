import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Adicionado
import 'package:solly/core/services/notification_service.dart';
import 'package:solly/features/home/presentation/home_page.dart';
import 'features/auth/presentation/auth_binding.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  // Injetamos o binding globalmente antes do app iniciar
  AuthBinding().dependencies();

  runApp(const SollyApp());
}

class SollyApp extends StatelessWidget {
  const SollyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Solly',
      debugShowCheckedModeBanner: false,

      // 🔥 Configuração de idioma para o Brasil
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // AuthGate decide qual tela mostrar
      home: const AuthGate(),
    );
  }
}

// Widget simples que ouve o estado de autenticação
class AuthGate extends GetView<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.currentUser.value != null) {
        // Usuário logado? Mostra a HomePage!
        return HomePage();
      }
      return const LoginPage();
    });
  }
}
