class VoiceParser {
  static Map<String, dynamic> analisarFrase(String texto) {
    String textoMin = texto.toLowerCase();
    DateTime dataAgendada = DateTime.now();
    String tipo = 'diario';
    double? valor;

    // 1. Detectar Data (ex: 28/03)
    final regexData = RegExp(r'(\d{1,2})/(\d{1,2})');
    final matchData = regexData.firstMatch(textoMin);
    if (matchData != null) {
      int dia = int.parse(matchData.group(1)!);
      int mes = int.parse(matchData.group(2)!);
      dataAgendada = DateTime(DateTime.now().year, mes, dia);
      tipo = 'tarefa'; // Se tem data, vira tarefa automaticamente
    }

    // 2. Detectar Hora (ex: 11h, 15:30)
    final regexHora = RegExp(r'(\d{1,2})[h:](\d{0,2})');
    final matchHora = regexHora.firstMatch(textoMin);
    if (matchHora != null) {
      int hora = int.parse(matchHora.group(1)!);
      int minuto = int.tryParse(matchHora.group(2)!) ?? 0;

      // Ajuste simples para "da manhã" ou "da tarde"
      if (textoMin.contains('tarde') && hora < 12) hora += 12;

      dataAgendada = DateTime(
        dataAgendada.year,
        dataAgendada.month,
        dataAgendada.day,
        hora,
        minuto,
      );
    }

    // 3. Detectar Valor (Gasto)
    final regexMoeda = RegExp(r'\d+([.,]\d+)?');
    if (textoMin.contains('gastei') || textoMin.contains('paguei')) {
      tipo = 'gasto';
      final matchValor = regexMoeda.firstMatch(textoMin);
      if (matchValor != null) {
        valor = double.tryParse(matchValor.group(0)!.replaceAll(',', '.'));
      }
    }

    return {
      'tipo': tipo,
      'valor': valor,
      'dataAgendada': dataAgendada,
      'isAgendado': matchData != null || matchHora != null,
    };
  }
}
