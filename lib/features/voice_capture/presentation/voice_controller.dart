import 'package:get/get.dart';
import 'package:solly/core/services/notification_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/voice_parser.dart';

class VoiceController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isListening = false.obs;
  final RxString textoReconhecido = 'Estou ouvindo...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
  }

  // Inicializa o microfone
  void _initSpeech() async {
    await _speechToText.initialize();
  }

  // Começa a gravar
  void startListening() async {
    textoReconhecido.value = 'Fale alguma coisa...';
    if (await _speechToText.hasPermission) {
      isListening.value = true;
      await _speechToText.listen(
        onResult: (result) {
          textoReconhecido.value = result.recognizedWords;

          // Se o usuário parou de falar (resultado final)
          if (result.finalResult) {
            isListening.value = false;
            _processarESalvar(result.recognizedWords);
          }
        },
        localeId: 'pt_BR', // Força o português do Brasil
      );
    } else {
      Get.snackbar('Permissão', 'O app precisa de acesso ao microfone.');
    }
  }

  // Para de gravar manualmente
  void stopListening() async {
    await _speechToText.stop();
    isListening.value = false;
  }

  // Passa no Cérebro e salva no Banco + Dá XP
  Future<void> _processarESalvar(String texto) async {
    if (texto.trim().isEmpty) {
      Get.back(); // Fecha a tela de voz
      return;
    }

    final user = _authController.currentUser.value;
    if (user == null) return;

    // 1. Passa na nossa inteligência
    final analise = VoiceParser.analisarFrase(texto);
    if (analise['isAgendado']) {
      await NotificationService.agendarLembrete(texto, analise['dataAgendada']);
    }

    // 2. Salva o registro
    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .add({
          'texto': texto,
          'tipo': analise['tipo'],
          'valor': analise['valor'],
          'createdAt': FieldValue.serverTimestamp(),
        });

    // 3. GAMIFICAÇÃO: Dá 10 de XP por usar a voz!
    await _firestore.collection('users').doc(user.id).update({
      'xpTotal': FieldValue.increment(10),
    });

    // Fecha a janelinha de voz e avisa o sucesso
    Get.back();
    Get.snackbar(
      'Salvo!',
      '+10 XP adicionado!',
      snackPosition: SnackPosition.TOP,
    );
  }
}
