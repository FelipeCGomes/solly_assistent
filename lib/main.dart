import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/auth_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init(); 
  
  // 🔥 REMOVIDO: AuthBinding().dependencies(); 
  // Nunca chame rotas ou injeções globais antes do runApp.
  
  runApp(const SollyApp());
}

class SollyApp extends StatelessWidget {
  const SollyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Solly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initialBinding: AuthBinding(), // 🔥 AQUI ESTÁ O SEGREDO: O GetX injeta na hora certa!
      // A tela inicial é um loading. O AuthController vai nos jogar para a tela certa em milissegundos.
      home: const Scaffold(body: Center(child: CircularProgressIndicator())), 
    );
  }
}