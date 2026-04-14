import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/registro_model.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<RegistroModel> registrosDoDia = <RegistroModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _ouvirRegistrosDoDia();
  }

  void _ouvirRegistrosDoDia() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);

    _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .where('createdAt', isGreaterThanOrEqualTo: inicioDoDia)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          // 🔥 CORREÇÃO 1: Usar assignAll em vez de .value para listas no GetX
          registrosDoDia.assignAll(
            snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  return data['arquivado'] != true;
                })
                .map((doc) => RegistroModel.fromJson(doc.data(), doc.id))
                .where((registro) => registro.tipo != 'privado')
                .toList(),
          );
        });
  }

  Future<void> adicionarRegistroTeste() async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .add({
          'texto': 'Gastei 25 reais no almoço',
          'tipo': 'gasto',
          'valor': 25.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> excluirRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    // 🔥 CORREÇÃO 2: Atualização Otimista (Some da tela na hora!)
    registrosDoDia.removeWhere((registro) => registro.id == id);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(id)
        .delete();

    Get.snackbar(
      'Excluído',
      'Registro removido com sucesso.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 2), // Some mais rápido pra não irritar
    );
  }

  Future<void> editarRegistro(RegistroModel registro, String novoTexto) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    // Atualização otimista também para a edição!
    final index = registrosDoDia.indexWhere((r) => r.id == registro.id);
    if (index != -1) {
      final old = registrosDoDia[index];
      registrosDoDia[index] = RegistroModel(
        id: old.id,
        texto: novoTexto,
        tipo: old.tipo,
        valor: old.valor,
        data: old.data,
      );
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(registro.id)
        .update({'texto': novoTexto});
  }

  Future<void> arquivarRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    // 🔥 Some da tela na hora!
    registrosDoDia.removeWhere((registro) => registro.id == id);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(id)
        .update({'arquivado': true});

    Get.snackbar(
      'Arquivado',
      'O registro não aparecerá mais hoje.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
