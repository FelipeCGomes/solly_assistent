import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroModel {
  final String id;
  final String texto;
  final String tipo; 
  final double? valor; 
  final DateTime data;
  final bool reagendado; // 🔥 Novo recurso

  RegistroModel({
    required this.id,
    required this.texto,
    required this.tipo,
    this.valor,
    required this.data,
    this.reagendado = false,
  });

  factory RegistroModel.fromJson(Map<String, dynamic> json, String id) {
    // 🔥 Puxa a data do agendamento primeiro. Se não tiver, puxa a de criação.
    final Timestamp? dataAgendada = json['dataAgendada'] as Timestamp?;
    final Timestamp? createdAt = json['createdAt'] as Timestamp?;
    
    return RegistroModel(
      id: id,
      texto: json['texto'] ?? '',
      tipo: json['tipo'] ?? 'outro',
      valor: json['valor']?.toDouble(),
      data: (dataAgendada ?? createdAt ?? Timestamp.now()).toDate(),
      reagendado: json['reagendado'] ?? false, 
    );
  }
}