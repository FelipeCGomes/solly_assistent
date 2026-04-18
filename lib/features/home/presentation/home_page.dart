import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:solly/features/calendar/presentation/calendar_page.dart';
import 'package:solly/features/voice_capture/presentation/secret_page.dart';
import 'package:solly/features/summary/presentation/summary_page.dart';
import 'package:solly/features/voice_capture/presentation/voice_bottom_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import 'home_controller.dart';
import '../data/registro_model.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

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
              Text('Olá, ${user?.nome.split(' ').first ?? 'Mestre'} 👋', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Nível ${user?.nivel} • ${user?.xpTotal} XP', style: TextStyle(fontSize: 12, color: context.theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            ],
          );
        }),
        actions: [
          IconButton(icon: Icon(Icons.pie_chart_outline, color: context.theme.colorScheme.primary), onPressed: () => Get.to(() => SummaryPage())),
          IconButton(icon: Icon(Icons.lock_person_outlined, color: context.theme.colorScheme.primary), onPressed: () => Get.to(() => SecretPage())),
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => Get.to(() => const CalendarPage())),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => authController.signOut()),
        ],
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDashboardCards(context),
            const SizedBox(height: 24),
            if (controller.proximosCompromissos.isNotEmpty) ...[
              const Text('Próximos Compromissos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.proximosCompromissos.take(3).map((registro) => _buildMiniCard(context, registro)),
              const SizedBox(height: 24),
            ],
            const Text('Atividades de Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (controller.registrosDoDia.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 32), child: Column(children: [Icon(Icons.mic_none, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Seu dia está em branco.\nToque no botão e fale algo!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500]))]))
            else
              ...controller.registrosDoDia.map((registro) => _buildTimelineCard(context, registro)),
            const SizedBox(height: 80),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Get.bottomSheet(VoiceBottomSheet(), isScrollControlled: true);
          Get.find<VoiceController>().iniciarModoNormal(); // 🔥 Chama o modo normal
        },
        backgroundColor: context.theme.colorScheme.primary,
        child: const Icon(Icons.mic, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.attach_money, color: Colors.redAccent), const SizedBox(height: 8), Text('Gastos de Hoje', style: TextStyle(fontSize: 12, color: Colors.grey[700])), Text('R\$ ${controller.gastoDoDia.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]))),
        const SizedBox(width: 16),
        Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: Colors.green), const SizedBox(height: 8), Text('Tarefas', style: TextStyle(fontSize: 12, color: Colors.grey[700])), Text('${controller.tarefasConcluidas} Concluídas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]))),
      ],
    );
  }

  Widget _buildMiniCard(BuildContext context, RegistroModel registro) {
    return Card(
      elevation: 0, color: context.theme.colorScheme.primary.withOpacity(0.05), margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.theme.colorScheme.primary.withOpacity(0.2))),
      child: ListTile(
        dense: true, leading: Icon(Icons.calendar_today, color: context.theme.colorScheme.primary, size: 20),
        title: Text(registro.texto, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text('${registro.data.day}/${registro.data.month} às ${registro.data.hour.toString().padLeft(2, '0')}:${registro.data.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, color: context.theme.colorScheme.primary)),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, RegistroModel registro) {
    IconData icone; Color cor;

    switch (registro.tipo) {
      case 'gasto': icone = Icons.attach_money; cor = Colors.redAccent; break;
      case 'ideia': icone = Icons.lightbulb_outline; cor = Colors.amber; break;
      case 'tarefa': icone = Icons.check_circle_outline; cor = Colors.green; break;
      case 'treino': icone = Icons.fitness_center; cor = Colors.deepPurpleAccent; break;
      default: icone = Icons.book_outlined; cor = Colors.blueGrey;
    }

    return Slidable(
      key: ValueKey(registro.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(onPressed: (_) => _mostrarDialogoEdicao(context, registro), backgroundColor: Colors.blue, foregroundColor: Colors.white, icon: Icons.edit, label: 'Editar', borderRadius: BorderRadius.circular(16)),
          SlidableAction(onPressed: (_) => controller.arquivarRegistro(registro.id), backgroundColor: Colors.grey, foregroundColor: Colors.white, icon: Icons.archive, label: 'Arquivar', borderRadius: BorderRadius.circular(16)),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: () => controller.excluirRegistro(registro.id)),
        children: [
          SlidableAction(onPressed: (_) => controller.excluirRegistro(registro.id), backgroundColor: Colors.red, foregroundColor: Colors.white, icon: Icons.delete, label: 'Excluir', borderRadius: BorderRadius.circular(16)),
        ],
      ),
      child: Stack(
        children: [
          Card(
            elevation: 0, color: cor.withOpacity(0.1), margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: cor.withOpacity(0.2), child: Icon(icone, color: cor)),
              title: Text(registro.texto, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${registro.data.hour.toString().padLeft(2, '0')}:${registro.data.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (registro.descricao != null && registro.descricao!.isNotEmpty)
                    Text(registro.descricao!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              isThreeLine: registro.descricao != null && registro.descricao!.isNotEmpty,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (registro.notificar5Min) const Icon(Icons.notifications_active, color: Colors.orange, size: 16),
                  if (registro.valor != null) Text(' R\$ ${registro.valor!.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 14)),
                ],
              )
            ),
          ),
          if (registro.reagendado)
            Positioned(top: 0, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Text('Reagendado', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicao(BuildContext context, RegistroModel registro) {
    final TextEditingController titleController = TextEditingController(text: registro.texto);
    final TextEditingController descController = TextEditingController(text: registro.descricao);
    DateTime dataSelecionada = registro.data;
    bool notificar5Min = registro.notificar5Min;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Registro'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: "Título", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month), label: Text('Data: ${dataSelecionada.day}/${dataSelecionada.month} - ${dataSelecionada.hour.toString().padLeft(2,'0')}:${dataSelecionada.minute.toString().padLeft(2,'0')}'),
                    onPressed: () async {
                      final date = await showDatePicker(context: context, initialDate: dataSelecionada, firstDate: DateTime(2023), lastDate: DateTime(2030));
                      if (date != null) {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dataSelecionada));
                        if (time != null) setState(() => dataSelecionada = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Avisar 5 min antes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    activeColor: Colors.orange,
                    value: notificar5Min,
                    onChanged: (val) => setState(() => notificar5Min = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) controller.editarRegistro(registro, titleController.text, descController.text, dataSelecionada, notificar5Min);
                  Get.back();
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        }
      ),
    );
  }
}