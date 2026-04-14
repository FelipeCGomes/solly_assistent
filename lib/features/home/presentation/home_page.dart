import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // 🔥 Import do Slidable adicionado
import 'package:solly/features/calendar/presentation/calendar_page.dart';
import 'package:solly/features/voice_capture/presentation/secret_page.dart';
import 'package:solly/features/summary/presentation/summary_page.dart';
import 'package:solly/features/voice_capture/presentation/voice_bottom_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import 'home_controller.dart';
import '../data/registro_model.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Injetamos o controller assim que a tela abre
  final HomeController controller = Get.put(HomeController());
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Obx(() {
          final user = authController.currentUser.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${user?.nome.split(' ').first ?? 'Mestre'} 👋',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Nível ${user?.nivel} • ${user?.xpTotal} XP',
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: Icon(
              Icons.pie_chart_outline,
              color: context.theme.colorScheme.primary,
            ),
            onPressed: () {
              Get.to(() => SummaryPage());
            },
          ),

          IconButton(
            icon: Icon(
              Icons.lock_person_outlined,
              color: context.theme.colorScheme.primary,
            ),
            onPressed: () {
              Get.to(() => SecretPage());
            },
          ),

          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Get.to(() => CalendarPage()),
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => authController.signOut(),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.registrosDoDia.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Seu dia está em branco.\nToque no botão e fale algo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.registrosDoDia.length,
          itemBuilder: (context, index) {
            final registro = controller.registrosDoDia[index];
            return _buildTimelineCard(context, registro);
          },
        );
      }),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPress: controller.adicionarRegistroTeste,
        child: FloatingActionButton.large(
          onPressed: () {
            Get.bottomSheet(VoiceBottomSheet(), isScrollControlled: true);
          },
          backgroundColor: context.theme.colorScheme.primary,
          child: const Icon(Icons.mic, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, RegistroModel registro) {
    IconData icone;
    Color cor;

    switch (registro.tipo) {
      case 'gasto':
        icone = Icons.attach_money;
        cor = Colors.redAccent;
        break;
      case 'ideia':
        icone = Icons.lightbulb_outline;
        cor = Colors.amber;
        break;
      case 'tarefa':
        icone = Icons.check_circle_outline;
        cor = Colors.green;
        break;
      case 'treino':
        icone = Icons.fitness_center;
        cor = Colors.deepPurpleAccent;
        break;
      default:
        icone = Icons.book_outlined;
        cor = Colors.blueGrey;
    }

    // 🔥 O CARD AGORA É ENVOLVIDO PELO SLIDABLE
    return Slidable(
      key: ValueKey(registro.id),
      // Ações ao deslizar para a DIREITA
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _mostrarDialogoEdicao(context, registro),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Editar',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) => controller.arquivarRegistro(registro.id),
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            icon: Icons.archive,
            label: 'Arquivar',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      // Ações ao deslizar para a ESQUERDA
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          onDismissed: () => controller.excluirRegistro(registro.id),
        ),
        children: [
          SlidableAction(
            onPressed: (_) => controller.excluirRegistro(registro.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Excluir',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: cor.withOpacity(0.1),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cor.withOpacity(0.2),
            child: Icon(icone, color: cor),
          ),
          title: Text(
            registro.texto,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${registro.data.hour.toString().padLeft(2, '0')}:${registro.data.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: registro.valor != null
              ? Text(
                  'R\$ ${registro.valor!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cor,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // 🔥 CAIXA DE DIÁLOGO PARA EDIÇÃO DE TEXTO
  void _mostrarDialogoEdicao(BuildContext context, RegistroModel registro) {
    final TextEditingController editController = TextEditingController(
      text: registro.texto,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Registro'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "O que você quis dizer?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
