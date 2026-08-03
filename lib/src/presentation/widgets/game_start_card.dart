import 'package:flutter/material.dart';
import 'package:serpiente_io/src/presentation/screens/game_screen.dart';

class GameStartCard extends StatelessWidget {
  const GameStartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Juego estilo Snake.io',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Controla una serpiente, recoge orbes y créce. Esta base inicial prepara la arquitectura para un juego escalable con lógica de negocio separada y soporte para skins.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameScreen(),
                  ),
                );
              },
              child: const Text('Iniciar partida'),
            ),
          ],
        ),
      ),
    );
  }
}
