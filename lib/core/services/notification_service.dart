import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    // 🔥 CORREÇÃO 1: Usando "settings:" de forma estritamente nomeada (0 argumentos posicionais)
    await _notifications.initialize(
      settings: initSettings,
    );
  }

  static Future<void> agendarLembrete(String titulo, DateTime data, {String? descricao, bool notificar5Min = false}) async {
    // 1. Notificação no dia pela manhã (08:00)
    final dataManha = DateTime(data.year, data.month, data.day, 8, 0);
    if (dataManha.isAfter(DateTime.now())) {
      await _agendar(
        titulo.hashCode + 1,
        'Solly: Compromisso Hoje',
        titulo,
        dataManha,
      );
    }

    // 2. Notificação de 5 Minutos antes
    if (notificar5Min) {
      final data5Min = data.subtract(const Duration(minutes: 5));
      if (data5Min.isAfter(DateTime.now())) {
        await _agendar(
          titulo.hashCode + 2,
          'Começa em 5 minutos! ⏰',
          titulo,
          data5Min,
        );
      }
    }
  }

  static Future<void> _agendar(int id, String titulo, String corpo, DateTime data) async {
    // 🔥 CORREÇÃO 2: Passando rigorosamente os nomes (id:, title:, body:, scheduledDate:)
    await _notifications.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      scheduledDate: tz.TZDateTime.from(data, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'solly_reminders',
          'Lembretes Solly',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}