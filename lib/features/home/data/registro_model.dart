import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroModel {
  final String id;
  final String texto;
  final String tipo;
  final double? valor;
  final DateTime data;
  final bool reagendado;
  final String? descricao; // 🔥 Novo campo
  final bool notificar5Min; // 🔥 Novo campo

  RegistroModel({
    required this.id,
    required this.texto,
    required this.tipo,
    this.valor,
    required this.data,
    this.reagendado = false,
    this.descricao,
    this.notificar5Min = false,
  });

  factory RegistroModel.fromJson(Map<String, dynamic> json, String id) {
    final Timestamp? dataAgendada = json['dataAgendada'] as Timestamp?;
    final Timestamp? createdAt = json['createdAt'] as Timestamp?;
    
    return RegistroModel(
      id: id,
      texto: json['texto'] ?? '',
      tipo: json['tipo'] ?? 'outro',
      valor: json['valor']?.toDouble(),
      data: (dataAgendada ?? createdAt ?? Timestamp.now()).toDate(),
      reagendado: json['reagendado'] ?? false,
      descricao: json['descricao'], // Lê do Firebase
      notificar5Min: json['notificar5Min'] ?? false, // Lê do Firebase
    );
  }
}