import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';
import 'user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  // Injeção de dependência opcional para facilitar testes no futuro
  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      // Busca os dados complementares (XP, nível) no Firestore
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      // 1. Inicia o fluxo do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuário cancelou o login

      // 2. Obtém os detalhes de autenticação da solicitação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Cria uma nova credencial para o Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Autentica no Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // 5. Verifica se o usuário já existe no Firestore
        final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // 6. É um usuário novo! Cria o documento com a estrutura inicial (Gamificação)
          final newUser = UserModel(
            id: firebaseUser.uid,
            nome: firebaseUser.displayName ?? 'Usuário',
            email: firebaseUser.email ?? '',
            xpTotal: 0,
            nivel: 1,
            isPremium: false,
          );

          await userDocRef.set({
            ...newUser.toJson(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          return newUser;
        } else {
          // Usuário já existe, retorna os dados do banco
          return UserModel.fromJson(userDoc.data()!, userDoc.id);
        }
      }
      return null;
    } catch (e) {
      // Em um app de produção, jogaríamos isso para um serviço de log (ex: Crashlytics)
      throw Exception('Erro ao fazer login com o Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
