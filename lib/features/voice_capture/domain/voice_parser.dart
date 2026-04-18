class VoiceParser {
  static Map<String, dynamic> analisarFrase(String texto) {
    String textoMin = texto.toLowerCase();
    DateTime dataAgendada = DateTime.now();
    String tipo = 'diario';
    double? valor;
    bool isAgendado = false;

    // 1. Detectar Data (ex: 14/04)
    final regexData = RegExp(r'(\d{1,2})/(\d{1,2})');
    final matchData = regexData.firstMatch(textoMin);
    if (matchData != null) {
      int dia = int.parse(matchData.group(1)!);
      int mes = int.parse(matchData.group(2)!);
      dataAgendada = DateTime(DateTime.now().year, mes, dia);
      tipo = 'tarefa'; 
      isAgendado = true;
    }

    // 2. Detectar Hora (ex: 14h, 14:30, 14 horas)
    final regexHora = RegExp(r'(\d{1,2})\s*(?:h|hora|horas|:)\s*(\d{0,2})');
    final matchHora = regexHora.firstMatch(textoMin);
    if (matchHora != null) {
      int hora = int.parse(matchHora.group(1)!);
      int minuto = 0;
      if (matchHora.group(2) != null && matchHora.group(2)!.isNotEmpty) {
        minuto = int.tryParse(matchHora.group(2)!) ?? 0;
      }

      if ((textoMin.contains('tarde') || textoMin.contains('noite')) && hora < 12) {
        hora += 12;
      }

      dataAgendada = DateTime(dataAgendada.year, dataAgendada.month, dataAgendada.day, hora, minuto);
      isAgendado = true;
    }

    // 3. Detectar Valor (Gasto)
    final regexMoeda = RegExp(r'\d+([.,]\d+)?');
    if (textoMin.contains('gastei') || textoMin.contains('paguei') || textoMin.contains('comprei')) {
      tipo = 'gasto';
      final matchValor = regexMoeda.firstMatch(textoMin);
      if (matchValor != null) {
        valor = double.tryParse(matchValor.group(0)!.replaceAll(',', '.'));
      }
    } else if (textoMin.contains('ideia') || textoMin.contains('pensei')) {
      tipo = 'ideia';
    }

    return {
      'tipo': tipo,
      'valor': valor,
      'dataAgendada': dataAgendada,
      'isAgendado': isAgendado,
    };
  }
}