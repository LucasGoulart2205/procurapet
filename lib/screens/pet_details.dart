import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petInfo;
  final String petId;
  final Function(String)? onDeleted; // ✅ callback para notificar exclusão

  const PetDetailsScreen({
    super.key,
    required this.petInfo,
    required this.petId,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          petInfo['nome'] ?? 'Detalhes do Pet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),

        /// 🔥 BOTÃO DE DELETAR PET
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Excluir Pet"),
                  content: const Text(
                    "Tem certeza que deseja excluir este pet? Esta ação não pode ser desfeita.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Excluir",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await FirebaseFirestore.instance
                    .collection('pets')
                    .doc(petId)
                    .delete();

                // ✅ chama o callback para remover o marcador do mapa
                if (onDeleted != null) onDeleted!(petId);

                Navigator.pop(context); // fecha detalhes e volta ao mapa
              }
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔹 CARD DE INFORMAÇÕES
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titulo('Informações Gerais'),
                const SizedBox(height: 8),
                _info('Espécie', petInfo['especie']),
                _info('Raça', petInfo['raca']),
                _info('Idade', petInfo['idade']),
                _info('Peso', petInfo['peso']),
                _info('Porte', petInfo['porte']),
                _info('Cor', petInfo['cor']),
                _info('Sexo', petInfo['sexo']),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔹 CARD DE DESCRIÇÃO/OBSERVAÇÕES
          if (petInfo['descricao'] != null &&
              petInfo['descricao'].toString().isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titulo('Observações'),
                  const SizedBox(height: 8),
                  Text(
                    petInfo['descricao'] ?? '—',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Título das seções
  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Colors.black87,
      ),
    );
  }

  /// 🔹 Linha de informação
  Widget _info(String titulo, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              valor?.isNotEmpty == true ? valor! : '—',
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
