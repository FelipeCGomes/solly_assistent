import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:solly/core/services/notification_service.dart';
import 'package:app_links/app_links.dart'; // 🔥 Lendo o Google a partir daqui!
import '../../auth/presentation/auth_controller.dart';
import '../data/registro_model.dart';
import '../../voice_capture/presentation/voice_bottom_sheet.dart';
import '../../voice_capture/presentation/voice_controller.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppLinks _appLinks;

  final RxList<RegistroModel> todosOsRegistros = <RegistroModel>[].obs;

  List<RegistroModel> get registrosDoDia {
    final hoje = DateTime.now();
    return todosOsRegistros.where((r) => isSameDay(r.data, hoje)).toList();
  }

  double get gastoDoDia {
    return registrosDoDia.where((r) => r.tipo == 'gasto').fold(0.0, (soma, r) => soma + (r.valor ?? 0.0));
  }

  int get tarefasConcluidas {
    return registrosDoDia.where((r) => r.tipo == 'tarefa').length;
  }

  List<RegistroModel> get proximosCompromissos {
    final hoje = DateTime.now();
    return todosOsRegistros.where((r) => r.tipo == 'tarefa' && r.data.isAfter(hoje)).toList()..sort((a, b) => a.data.compareTo(b.data));
  }

  @override
  void onInit() {
    super.onInit();
    _ouvirRegistrosGlobais();
    _ouvirComandosDoGoogle(); // 🔥 Ativa o ouvinte assim que a Home carrega
  }

  // 🔥 OUVINTE DE COMANDOS EXTERNOS (GOOGLE ASSISTENTE)
  void _ouvirComandosDoGoogle() {
    _appLinks = AppLinks();
    
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'solly' && uri.host == 'assistente') {
        // Dá meio segundo pra garantir que a tela focou e sobe a voz!
        Future.delayed(const Duration(milliseconds: 500), () {
          // Se o bottomsheet já estiver aberto, não abre outro
          if (!(Get.isBottomSheetOpen ?? false)) {
            Get.bottomSheet(VoiceBottomSheet(), isScrollControlled: true);
            final voiceController = Get.put(VoiceController());
            voiceController.iniciarPeloGoogle();
          }
        });
      }
    });
  }

  void _ouvirRegistrosGlobais() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    _firestore.collection('users').doc(user.id).collection('registros').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      todosOsRegistros.assignAll(
        snapshot.docs.where((doc) => doc.data()['arquivado'] != true).map((doc) => RegistroModel.fromJson(doc.data(), doc.id)).where((registro) => registro.tipo != 'privado').toList(),
      );
    });
  }

  Future<void> adicionarTarefaManual(String texto, String? descricao, DateTime data, bool notificar5Min) async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    await _firestore.collection('users').doc(user.id).collection('registros').add({
      'texto': texto,
      'descricao': descricao,
      'notificar5Min': notificar5Min,
      'tipo': 'tarefa',
      'dataAgendada': Timestamp.fromDate(data),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.agendarLembrete(texto, data, descricao: descricao, notificar5Min: notificar5Min);
    Get.snackbar('Sucesso', 'Compromisso agendado no calendário!', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
  }

  Future<void> adicionarRegistroTeste() async {
    final user = _authController.currentUser.value;
    if (user == null) return;
    await _firestore.collection('users').doc(user.id).collection('registros').add({
      'texto': 'Gastei 25 reais no almoço', 'tipo': 'gasto', 'valor': 25.0, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;
    todosOsRegistros.removeWhere((registro) => registro.id == id);
    await _firestore.collection('users').doc(userId).collection('registros').doc(id).delete();
  }

  Future<void> editarRegistro(RegistroModel registro, String novoTexto, String? novaDescricao, DateTime novaData, bool novoNotificar) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    bool foiReagendado = !isSameDay(registro.data, novaData);

    await _firestore.collection('users').doc(userId).collection('registros').doc(registro.id).update({
      'texto': novoTexto,
      'descricao': novaDescricao,
      'notificar5Min': novoNotificar,
      'dataAgendada': Timestamp.fromDate(novaData),
      'reagendado': foiReagendado || registro.reagendado,
    });
    
    if(foiReagendado || novoNotificar != registro.notificar5Min) {
       await NotificationService.agendarLembrete(novoTexto, novaData, descricao: novaDescricao, notificar5Min: novoNotificar);
    }
  }

  Future<void> arquivarRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;
    todosOsRegistros.removeWhere((registro) => registro.id == id);
    await _firestore.collection('users').doc(userId).collection('registros').doc(id).update({'arquivado': true});
  }
}