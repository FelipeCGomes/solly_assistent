import 'package:get/get.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Injeta a implementação real do repositório (Firebase)
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl());

    // 2. Injeta o Controller, passando o repositório que acabamos de criar
    Get.lazyPut<AuthController>(() => AuthController(Get.find()));
  }
}
