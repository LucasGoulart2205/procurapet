import 'package:flutter/material.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petInfo;

  const PetDetailsScreen({super.key, required this.petInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes de ${petInfo['nome']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _info('Nome', petInfo['nome']),
            _info('Espécie', petInfo['especie']),
            _info('Raça', petInfo['raca']),
            _info('Idade', petInfo['idade']),
            _info('Peso', petInfo['peso']),
            _info('Altura', petInfo['altura']),
            _info('Cor', petInfo['cor']),
            _info('Sexo', petInfo['sexo']),
            const SizedBox(height: 8),
            const Text(
              'Descrição / Observações:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(petInfo['descricao'] ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _info(String titulo, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(valor?.isNotEmpty == true ? valor! : '—')),
        ],
      ),
    );
  }
}
