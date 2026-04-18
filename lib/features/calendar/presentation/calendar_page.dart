import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import '../../home/presentation/home_controller.dart';
import '../../home/data/registro_model.dart'; // Precisa desse import agora

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  final HomeController controller = Get.find<HomeController>();

  // 🔥 Essa função é o coração do calendário: ela diz pro pacote quais dias têm evento
  List<RegistroModel> _getEventosDoDia(DateTime day) {
    return controller.todosOsRegistros.where((r) => isSameDay(r.data, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário Solly')),
      body: Column(
        children: [
          Obx(() {
            // Força o calendário a redesenhar se a lista global mudar
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
              eventLoader: _getEventosDoDia, // 🔥 AQUI ESTÁ O QUE PINTA A BOLINHA!
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: context.theme.colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: context.theme.colorScheme.primary, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle), // A cor da bolinha
              ),
            );
          }),
          const Divider(),
          Expanded(
            child: Obx(() {
              final compromissos = _getEventosDoDia(_selectedDay ?? DateTime.now());

              if (compromissos.isEmpty) {
                return const Center(child: Text('Nenhum compromisso para este dia.'));
              }

              return ListView.builder(
                itemCount: compromissos.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(compromissos[index].texto),
                  subtitle: Text('${compromissos[index].data.hour}:${compromissos[index].data.minute.toString().padLeft(2, '0')}'),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}