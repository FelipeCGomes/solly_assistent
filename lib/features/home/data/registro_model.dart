import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroModel {
  final String id;
  final String texto;
  final String tipo; // gasto, ideia, tarefa, diario, treino
  final double? valor; // Se for gasto, salva o valor aqui
  final DateTime data;

  RegistroModel({
    required this.id,
    required this.texto,
    required this.tipo,
    this.valor,
    required this.data,
  });

  factory RegistroModel.fromJson(Map<String, dynamic> json, String id) {
    return RegistroModel(
      id: id,
      texto: json['texto'] ?? '',
      tipo: json['tipo'] ?? 'outro',
      valor: json['valor']?.toDouble(),
      data: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
