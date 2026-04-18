import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'voice_controller.dart';

class VoiceBottomSheet extends StatelessWidget {
  VoiceBottomSheet({super.key});

  final VoiceController controller = Get.put(VoiceController());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: controller.isListening.value 
                  ? context.theme.colorScheme.primary.withOpacity(0.1) 
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.isListening.value ? Icons.mic : Icons.mic_none,
              size: 64,
              color: controller.isListening.value 
                  ? context.theme.colorScheme.primary 
                  : Colors.grey,
            ),
          )),
          const SizedBox(height: 32),
          Obx(() => Text(
            controller.textoReconhecido.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              // Muda a cor se for a Solly falando
              color: controller.textoReconhecido.value.startsWith("Solly:") 
                  ? context.theme.colorScheme.primary 
                  : Colors.black87,
            ),
          )),
        ],
      ),
    );
  }
}