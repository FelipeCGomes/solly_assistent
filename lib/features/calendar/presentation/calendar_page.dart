import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/data/registro_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  final HomeController controller = Get.find<HomeController>();

  List<RegistroModel> _getEventosDoDia(DateTime day) {
    return controller.todosOsRegistros.where((r) => isSameDay(r.data, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário Solly', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Obx(() {
            final _ = controller.todosOsRegistros.length;
            return TableCalendar<RegistroModel>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventosDoDia,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: context.theme.colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: context.theme.colorScheme.primary, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            );
          }),
          const Divider(),
          Expanded(
            child: Obx(() {
              final compromissos = _getEventosDoDia(_selectedDay ?? DateTime.now());

              if (compromissos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Dia livre! Nenhum compromisso.', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: compromissos.length,
                itemBuilder: (context, index) {
                  final registro = compromissos[index];
                  return _buildTimelineCard(context, registro); 
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNovaTarefa(context),
        backgroundColor: context.theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🔥 O NOVO POP-UP COM DESCRIÇÃO E NOTIFICAÇÃO 5 MIN
  void _mostrarDialogoNovaTarefa(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    TimeOfDay horaSelecionada = TimeOfDay.now();
    bool notificar5Min = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder permite atualizar checkboxes dentro do pop-up
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Novo Compromisso em ${_selectedDay?.day}/${_selectedDay?.month}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: "Título (ex: Reunião)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Descrição (opcional)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time), label: Text('Horário: ${horaSelecionada.hour.toString().padLeft(2,'0')}:${horaSelecionada.minute.toString().padLeft(2,'0')}'),
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: horaSelecionada);
                      if (time != null) setState(() => horaSelecionada = time);
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
                  if (titleController.text.isNotEmpty) {
                    final dataFinal = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, horaSelecionada.hour, horaSelecionada.minute);
                    controller.adicionarTarefaManual(titleController.text, descController.text, dataFinal, notificar5Min);
                  }
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

  // 🔥 O CARD COM A DESCRIÇÃO E O SINO
  Widget _buildTimelineCard(BuildContext context, RegistroModel registro) {
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
            elevation: 0, color: context.theme.colorScheme.primary.withOpacity(0.08), margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: context.theme.colorScheme.primary.withOpacity(0.2), child: Icon(Icons.alarm, color: context.theme.colorScheme.primary)),
              title: Text(registro.texto, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horário: ${registro.data.hour.toString().padLeft(2, '0')}:${registro.data.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.grey[700])),
                  if (registro.descricao != null && registro.descricao!.isNotEmpty)
                    Text(registro.descricao!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              isThreeLine: registro.descricao != null && registro.descricao!.isNotEmpty,
              trailing: registro.notificar5Min ? const Icon(Icons.notifications_active, color: Colors.orange, size: 20) : null,
            ),
          ),
          if (registro.reagendado)
            Positioned(top: 0, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Text('Reagendado', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  // 🔥 O NOVO POP-UP DE EDIÇÃO
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
            title: const Text('Editar Compromisso'),
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