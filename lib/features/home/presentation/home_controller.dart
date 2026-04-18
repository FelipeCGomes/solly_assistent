import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/registro_model.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Guarda TODOS os registros para alimentar o calendário
  final RxList<RegistroModel> todosOsRegistros = <RegistroModel>[].obs;

  // 🔥 Filtra automaticamente os registros de hoje para mostrar na Home
  List<RegistroModel> get registrosDoDia {
    final hoje = DateTime.now();
    return todosOsRegistros.where((r) => isSameDay(r.data, hoje)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _ouvirRegistrosGlobais();
  }

  void _ouvirRegistrosGlobais() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          todosOsRegistros.assignAll(
            snapshot.docs
                .where((doc) => doc.data()['arquivado'] != true)
                .map((doc) => RegistroModel.fromJson(doc.data(), doc.id))
                .where((registro) => registro.tipo != 'privado')
                .toList(),
          );
        });
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

  // 🔥 FUNÇÃO DE EDIÇÃO COM REAGENDAMENTO
  Future<void> editarRegistro(RegistroModel registro, String novoTexto, DateTime novaData) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    bool foiReagendado = !isSameDay(registro.data, novaData);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(registro.id)
        .update({
          'texto': novoTexto,
          'dataAgendada': Timestamp.fromDate(novaData),
          'reagendado': foiReagendado || registro.reagendado,
        });
  }

  Future<void> arquivarRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    todosOsRegistros.removeWhere((registro) => registro.id == id);
    await _firestore.collection('users').doc(userId).collection('registros').doc(id).update({'arquivado': true});
  }
}