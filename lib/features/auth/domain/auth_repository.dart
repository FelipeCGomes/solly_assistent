import 'user_entity.dart';

// Esta é a interface. O "Clean" entra aqui: nossa tela de login
// vai chamar essas funções sem saber se é Firebase, Supabase ou API própria.
abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Stream<UserEntity?>
  get authStateChanges; // Para ouvir se o usuário logou/deslogou
}

