import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // 🔥 Import do Slidable adicionado
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/registro_model.dart';

// ==========================================
// O CONTROLADOR DA ÁREA SECRETA
// ==========================================
class SecretController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isUnlocked = false.obs;
  final RxList<RegistroModel> notasPrivadas = <RegistroModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    autenticar(); // Pede a digital assim que abre a tela
  }

  Future<void> autenticar() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        Get.snackbar('Erro', 'Seu dispositivo não suporta biometria.');
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Desbloqueie para ver seus Registros Pessoais',
        options: const AuthenticationOptions(
          biometricOnly:
              false, // Permite usar a senha/padrão do celular se a digital falhar
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        isUnlocked.value = true;
        _buscarNotasPrivadas();
      } else {
        Get.back(); // Se cancelar a digital, expulsa da tela secreta
      }
    } catch (e) {
      Get.snackbar('Erro', 'Falha na autenticação: $e');
    }
  }

  void _buscarNotasPrivadas() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.id)
        .collection('registros')
        .where('tipo', isEqualTo: 'privado')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          // 🔥 assignAll garantindo a atualização!
          notasPrivadas.assignAll(
            snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  return data['arquivado'] != true;
                })
                .map((doc) => RegistroModel.fromJson(doc.data(), doc.id))
                .toList(),
          );
        });
  }

  // Substitua excluir, editar e arquivar por estas com Atualização Otimista:
  Future<void> excluirRegistro(String id) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    notasPrivadas.removeWhere((nota) => nota.id == id); // Some da tela

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(id)
        .delete();
  }

  Future<void> editarRegistro(RegistroModel registro, String novoTexto) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    final index = notasPrivadas.indexWhere((n) => n.id == registro.id);
    if (index != -1) {
      final old = notasPrivadas[index];
      notasPrivadas[index] = RegistroModel(
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

    notasPrivadas.removeWhere((nota) => nota.id == id); // Some da tela

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('registros')
        .doc(id)
        .update({'arquivado': true});
  }
}

// ==========================================
// A TELA DA ÁREA SECRETA
// ==========================================
class SecretPage extends StatelessWidget {
  SecretPage({super.key});

  final SecretController controller = Get.put(SecretController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Fundo escuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Área Segura',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (!controller.isUnlocked.value) {
          return const Center(
            child: Icon(Icons.lock, size: 80, color: Colors.white24),
          );
        }

        if (controller.notasPrivadas.isEmpty) {
          return Center(
            child: Text(
              'Nenhum registro pessoal ainda.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notasPrivadas.length,
          itemBuilder: (context, index) {
            final nota = controller.notasPrivadas[index];

            // 🔥 ADICIONANDO O SLIDABLE AQUI
            return Slidable(
              key: ValueKey(nota.id),
              startActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _mostrarDialogoEdicao(context, nota),
                    backgroundColor: Colors.blueGrey, // Cor mais discreta
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Editar',
                    borderRadius: BorderRadius.circular(16),
                  ),
                  SlidableAction(
                    onPressed: (_) => controller.arquivarRegistro(nota.id),
                    backgroundColor: Colors.grey[700]!, // Cinza escuro
                    foregroundColor: Colors.white,
                    icon: Icons.archive,
                    label: 'Arquivar',
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                dismissible: DismissiblePane(
                  onDismissed: () => controller.excluirRegistro(nota.id),
                ),
                children: [
                  SlidableAction(
                    onPressed: (_) => controller.excluirRegistro(nota.id),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Excluir',
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              child: Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.security, color: Colors.tealAccent),
                  title: Text(
                    nota.texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${nota.data.day}/${nota.data.month} às ${nota.data.hour.toString().padLeft(2, '0')}:${nota.data.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // 🔥 CAIXA DE DIÁLOGO DE EDIÇÃO (THEMA ESCURO)
  void _mostrarDialogoEdicao(BuildContext context, RegistroModel registro) {
    final TextEditingController editController = TextEditingController(
      text: registro.texto,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // Combina com a tela secreta
        title: const Text(
          'Editar Registro',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
          ), // Texto branco ao digitar
          decoration: InputDecoration(
            hintText: "O que você quis dizer?",
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.tealAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal, // Cor de destaque
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (editController.text.isNotEmpty) {
                controller.editarRegistro(registro, editController.text);
              }
              Get.back();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
