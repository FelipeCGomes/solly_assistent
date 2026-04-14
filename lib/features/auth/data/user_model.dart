import '../domain/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.nome,
    required super.email,
    super.xpTotal,
    super.nivel,
    super.isPremium,
  });

  // Transforma o JSON do Firestore no nosso objeto
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      nome: json['nome'] ?? 'Usuário',
      email: json['email'] ?? '',
      xpTotal: json['xpTotal'] ?? 0,
      nivel: json['nivel'] ?? 1,
      isPremium: json['isPremium'] ?? false,
    );
  }

  // Transforma o nosso objeto num JSON para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'xpTotal': xpTotal,
      'nivel': nivel,
      'isPremium': isPremium,
      // createdAt pode ser adicionado direto no repositório com o FieldValue.serverTimestamp()
    };
  }
}

