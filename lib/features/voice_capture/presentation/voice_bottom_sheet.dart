import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'voice_controller.dart';

class VoiceBottomSheet extends StatelessWidget {
  VoiceBottomSheet({super.key});

  final VoiceController controller = Get.put(VoiceController());

  @override
  Widget build(BuildContext context) {
    // Começa a ouvir automaticamente assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startListening();
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ocupa só o espaço necessário
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // O Texto Mágico
          Obx(
            () => Text(
              controller.textoReconhecido.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 40),

          // Botão animado (Simples com o GetX)
          Obx(
            () => GestureDetector(
              onTap: () {
                if (controller.isListening.value) {
                  controller.stopListening();
                } else {
                  controller.startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: controller.isListening.value ? 90 : 70,
                height: controller.isListening.value ? 90 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: controller.isListening.value
                      ? Colors.redAccent.withOpacity(0.2)
                      : context.theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    controller.isListening.value ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: controller.isListening.value
                        ? Colors.redAccent
                        : context.theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fale "Gastei 20 reais" ou "Tive uma ideia"',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
