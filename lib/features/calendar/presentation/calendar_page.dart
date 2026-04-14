import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import '../../home/presentation/home_controller.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário Solly')),
      body: Column(
        children: [
          TableCalendar(
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
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: context.theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: context.theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              // Filtra os registros para o dia selecionado
              final compromissos = controller.registrosDoDia
                  .where(
                    (r) => isSameDay(r.data, _selectedDay ?? DateTime.now()),
                  )
                  .toList();

              if (compromissos.isEmpty) {
                return const Center(
                  child: Text('Nenhum compromisso para este dia.'),
                );
              }

              return ListView.builder(
                itemCount: compromissos.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(compromissos[index].texto),
                  subtitle: Text(
                    '${compromissos[index].data.hour}:${compromissos[index].data.minute}',
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
