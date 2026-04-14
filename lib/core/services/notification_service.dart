import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // Configuração do ícone para Android
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // A classe agora se chama Darwin...
    const darwin = DarwinInitializationSettings();

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS:
            darwin, // 🔥 A CORREÇÃO ESTÁ AQUI: O parâmetro continua sendo 'iOS'
      ),
    );
  }

  static Future<void> agendarLembrete(String titulo, DateTime data) async {
    // 1. Notificação 15 minutos antes
    final data15Min = data.subtract(const Duration(minutes: 15));
    if (data15Min.isAfter(DateTime.now())) {
      await _agendar(
        id: titulo.hashCode, // Gera um ID único baseado no texto
        titulo: 'Solly: Lembrete em 15min',
        corpo: titulo,
        data: data15Min,
      );
    }

    // 2. Notificação no dia pela manhã (08:00)
    final dataManha = DateTime(data.year, data.month, data.day, 8, 0);
    if (dataManha.isAfter(DateTime.now())) {
      await _agendar(
        id:
            titulo.hashCode +
            1, // ID diferente para não sobrescrever a de 15min
        titulo: 'Solly: Você tem um compromisso hoje',
        corpo: titulo,
        data: dataManha,
      );
    }
  }

  static Future<void> _agendar({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime data,
  }) async {
    // Agora o zonedSchedule usa apenas parâmetros nomeados
    await _notifications.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      scheduledDate: tz.TZDateTime.from(data, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'solly_reminders', // ID do canal
          'Lembretes Solly', // Nome do canal
          importance: Importance.max,
          priority: Priority
              .high, // Adicionado para garantir que o aviso apareça no topo
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // O uiLocalNotificationDateInterpretation foi removido do pacote
    );
  }
}
