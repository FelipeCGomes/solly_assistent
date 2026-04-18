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

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  void startListening() async {
    textoReconhecido.value = 'Fale alguma coisa...';
    if (await _speechToText.hasPermission) {
      isListening.value = true;
      await _speechToText.listen(
        onResult: (result) {
          textoReconhecido.value = result.recognizedWords;
          if (result.finalResult) {
            isListening.value = false;
            _processarESalvar(result.recognizedWords);
          }
        },
        localeId: 'pt_BR', 
      );
    } else {
      Get.snackbar('Permissão', 'O app precisa de acesso ao microfone.');
    }
  }

  void stopListening() async {
    await _speechToText.stop();
    isListening.value = false;
  }

  Future<void> _processarESalvar(String texto) async {
    if (texto.trim().isEmpty) {
      Get.back(); 
      return;
    }

    final user = _authController.currentUser.value;
    if (user == null) return;

    final analise = VoiceParser.analisarFrase(texto);
    if (analise['isAgendado']) {
      await NotificationService.agendarLembrete(texto, analise['dataAgendada']);
    }

    // 🔥 A CORREÇÃO PRINCIPAL: Salvando a dataAgendada no Firebase
    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .add({
          'texto': texto,
          'tipo': analise['tipo'],
          'valor': analise['valor'],
          'dataAgendada': analise['isAgendado'] 
              ? Timestamp.fromDate(analise['dataAgendada']) 
              : null, 
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('users').doc(user.id).update({
      'xpTotal': FieldValue.increment(10),
    });

    Get.back();
    Get.snackbar('Salvo!', '+10 XP adicionado!', snackPosition: SnackPosition.TOP);
  }
}