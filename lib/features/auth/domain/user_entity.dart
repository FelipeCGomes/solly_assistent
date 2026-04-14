class UserEntity {
  final String id;
  final String nome;
  final String email;
  final int xpTotal;
  final int nivel;
  final bool isPremium;

  UserEntity({
    required this.id,
    required this.nome,
    required this.email,
    this.xpTotal = 0,
    this.nivel = 1,
    this.isPremium = false,
  });
}
