import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/presentation/home_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/voice_parser.dart';

enum VoiceState { idle, waitingCommand, waitingDetails, waitingConfirmation }

class VoiceController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  final HomeController _homeController = Get.find<HomeController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isListening = false.obs;
  final RxString textoReconhecido = 'Inicializando...'.obs;
  final Rx<VoiceState> currentState = VoiceState.idle.obs;

  Map<String, dynamic>? _tempLembrete;

  @override
  void onInit() {
    super.onInit();
    _initSpeechAndTts();
  }

  Future<void> _initSpeechAndTts() async {
    await _speechToText.initialize();
    await _tts.setLanguage("pt-BR");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.1);
    await _tts.awaitSpeakCompletion(true); 
  }

  // 🔥 FUNÇÃO 1: Chamada quando clica no botão da Home
  void iniciarModoNormal() async {
    currentState.value = VoiceState.waitingCommand;
    await _falar("Olá! O que deseja?");
  }

  // 🔥 FUNÇÃO 2: Chamada pelo "Ok Google"
  void iniciarPeloGoogle() async {
    currentState.value = VoiceState.waitingDetails;
    await _falar("Claro. O que você quer que eu lembre?");
  }

  void startListening() async {
    if (await _speechToText.hasPermission) {
      isListening.value = true;
      
      switch(currentState.value) {
        case VoiceState.waitingCommand: textoReconhecido.value = 'Solly: Ouvindo comando...'; break;
        case VoiceState.waitingDetails: textoReconhecido.value = 'Solly: Descreva o lembrete...'; break;
        case VoiceState.waitingConfirmation: textoReconhecido.value = 'Solly: Diga Sim ou Não...'; break;
        default: break;
      }

      await _speechToText.listen(
        onResult: (result) {
          textoReconhecido.value = result.recognizedWords;
          if (result.finalResult) {
            isListening.value = false;
            _processarConversa(result.recognizedWords.toLowerCase());
          }
        },
        localeId: 'pt_BR',
      );
    }
  }

  Future<void> _falar(String texto) async {
    await _speechToText.stop();
    textoReconhecido.value = "Solly: $texto";
    await _tts.speak(texto);
    startListening(); // Volta a ouvir assim que termina de falar
  }

  Future<void> _processarConversa(String texto) async {
    switch (currentState.value) {
      
      case VoiceState.waitingCommand:
        if (texto.contains('criar lembrete') || texto.contains('lembrete')) {
          currentState.value = VoiceState.waitingDetails;
          await _falar("Claro, pode me dizer o que é?");
        } else {
          await _salvarFluxoNormal(texto);
        }
        break;

      case VoiceState.waitingDetails:
        _tempLembrete = VoiceParser.analisarFrase(texto);
        _tempLembrete!['texto_original'] = texto;
        currentState.value = VoiceState.waitingConfirmation;
        await _falar("Registrado. Gostaria de ser lembrado 5 minutos antes?");
        break;

      case VoiceState.waitingConfirmation:
        bool notificar5Min = texto.contains('sim') || texto.contains('quero') || texto.contains('pode') || texto.contains('claro');

        await _homeController.adicionarTarefaManual(
          _tempLembrete!['texto_original'],
          null, 
          _tempLembrete!['dataAgendada'],
          notificar5Min,
        );

        currentState.value = VoiceState.idle;
        await _falar("Lembrete criado.");
        
        Future.delayed(const Duration(seconds: 2), () {
            if(Get.isBottomSheetOpen ?? false) Get.back();
        });
        break;
        
      default: break;
    }
  }

  Future<void> _salvarFluxoNormal(String texto) async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    final analise = VoiceParser.analisarFrase(texto);
    await _firestore.collection('users').doc(user.id).collection('registros').add({
      'texto': texto,
      'tipo': analise['tipo'],
      'valor': analise['valor'],
      'dataAgendada': analise['isAgendado'] ? Timestamp.fromDate(analise['dataAgendada']) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _falar("Registrado.");
    Future.delayed(const Duration(seconds: 2), () {
        if(Get.isBottomSheetOpen ?? false) Get.back();
    });
  }
}