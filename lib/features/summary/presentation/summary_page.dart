import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/presentation/home_controller.dart';

class SummaryPage extends StatelessWidget {
  SummaryPage({super.key});

  // Puxamos o mesmo controller da Home que já tem os dados de hoje!
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Resumo de Hoje',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        final registros = controller.registrosDoDia;

        // 🧮 CÁLCULOS EM TEMPO REAL
        // Soma todos os valores onde o tipo é 'gasto'
        final totalGasto = registros
            .where((r) => r.tipo == 'gasto')
            .fold(0.0, (soma, item) => soma + (item.valor ?? 0.0));

        final tarefasFeitas = registros.where((r) => r.tipo == 'tarefa').length;
        final ideiasCriadas = registros.where((r) => r.tipo == 'ideia').length;
        final treinosFeitos = registros.where((r) => r.tipo == 'treino').length;

        // 🤖 Cérebro da Produtividade (Lógica simples para gerar a frase)
        String fraseProdutividade =
            'O dia está só começando! Fale com o Solly.';
        Color corProdutividade = Colors.grey;
        double progresso = 0.0;

        int pontosPositivos = tarefasFeitas + ideiasCriadas + treinosFeitos;

        if (registros.isNotEmpty) {
          if (pontosPositivos >= 5) {
            fraseProdutividade =
                'Máquina de vencer! Hoje você foi 100% produtivo 🔥';
            corProdutividade = Colors.green;
            progresso = 1.0;
          } else if (pontosPositivos >= 2) {
            fraseProdutividade =
                'Muito bem! Você está tendo um dia produtivo 🚀';
            corProdutividade = Colors.blueAccent;
            progresso = 0.6;
          } else if (totalGasto > 0 && pontosPositivos == 0) {
            fraseProdutividade =
                'Dia focado em gastos. Que tal registrar uma ideia? 💡';
            corProdutividade = Colors.orange;
            progresso = 0.3;
          } else {
            fraseProdutividade =
                'Você está no caminho. Continue registrando! 📈';
            corProdutividade = Colors.purpleAccent;
            progresso = 0.4;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📈 CARD DE PRODUTIVIDADE (Destaque)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      corProdutividade.withOpacity(0.8),
                      corProdutividade,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      fraseProdutividade,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seus Números',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 📊 GRID DE ESTATÍSTICAS
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      'Gasto Total',
                      'R\$ ${totalGasto.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.redAccent,
                    ),
                    _buildStatCard(
                      'Tarefas',
                      tarefasFeitas.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Ideias',
                      ideiasCriadas.toString(),
                      Icons.lightbulb,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'Treinos',
                      treinosFeitos.toString(),
                      Icons.fitness_center,
                      Colors.deepPurpleAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Widget reaproveitável para os quadradinhos do Grid
  Widget _buildStatCard(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: cor, size: 36),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
