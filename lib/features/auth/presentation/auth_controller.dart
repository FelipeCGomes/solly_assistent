import 'package:get/get.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;

  // Injeção de dependência via construtor
  AuthController(this._authRepository);

  // Variáveis Reativas (O .obs e Rx tornam a variável observável pela tela)
  final Rx<UserEntity?> currentUser = Rx<UserEntity?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Liga o fluxo de autenticação do Firebase diretamente à nossa variável reativa
    currentUser.bindStream(_authRepository.authStateChanges);
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true; // Mostra o loading na tela

      final user = await _authRepository.signInWithGoogle();

      if (user != null) {
        Get.snackbar(
          'Sucesso!',
          'Bem-vindo de volta, ${user.nome.split(' ').first}!',
          snackPosition: SnackPosition.BOTTOM,
        );
        // O bindStream ali em cima já vai atualizar o currentUser e mudar a tela
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível fazer login. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false; // Esconde o loading
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}
