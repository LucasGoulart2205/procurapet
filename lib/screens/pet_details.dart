import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> petInfo;
  final String petId;
  final Function(String)? onDeleted;

  const PetDetailsScreen({
    super.key,
    required this.petInfo,
    required this.petId,
    this.onDeleted,
  });

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviando = false;

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .collection('comentarios')
          .add({
        'texto': texto,
        'userId': user?.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      _comentarioController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar comentário: $e")),
      );
    }

    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: Text(
          widget.petInfo['nome'] ?? "Detalhes do Pet",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Excluir Pet"),
                  content: const Text("Tem certeza que deseja excluir este pet?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirmar == true) {
                await FirebaseFirestore.instance.collection('pets').doc(widget.petId).delete();
                widget.onDeleted?.call(widget.petId);
                Navigator.pop(context);
              }
            },
          )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardInformacoes(),
          const SizedBox(height: 20),
          _cardDescricao(),
          const SizedBox(height: 25),
          _titulo("Comentários"),
          const SizedBox(height: 10),

          _campoAdicionarComentario(),
          const SizedBox(height: 10),

          _listaComentarios(),
        ],
      ),
    );
  }

  Widget _cardInformacoes() {
    return Container(
      decoration: _dec(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo("Informações Gerais"),
          const SizedBox(height: 8),
          _info("Espécie", widget.petInfo['especie']),
          _info("Raça", widget.petInfo['raca']),
          _info("Idade", widget.petInfo['idade']),
          _info("Peso", widget.petInfo['peso']),
          _info("Porte", widget.petInfo['porte']),
          _info("Cor", widget.petInfo['cor']),
          _info("Sexo", widget.petInfo['sexo']),
        ],
      ),
    );
  }

  Widget _cardDescricao() {
    if (widget.petInfo['descricao'] == null || widget.petInfo['descricao'].toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: _dec(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo("Observações"),
          const SizedBox(height: 8),
          Text(widget.petInfo['descricao'], style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _campoAdicionarComentario() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _dec(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                hintText: "Escreva um comentário...",
                border: InputBorder.none,
              ),
            ),
          ),

          _enviando
              ? const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : IconButton(
            icon: const Icon(Icons.send, color: Colors.teal),
            onPressed: _enviarComentario,
          ),
        ],
      ),
    );
  }

  Widget _listaComentarios() {
    return Container(
      decoration: _dec(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.petId)
            .collection('comentarios')
            .orderBy('criadoEm', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Nenhum comentário ainda."),
            );
          }

          return Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['texto'] ?? ''),
                subtitle: Text(
                  data['criadoEm'] == null
                      ? "Enviando..."
                      : (data['criadoEm'] as Timestamp).toDate().toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                leading: const Icon(Icons.person, color: Colors.teal),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  BoxDecoration _dec() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _titulo(String texto) {
    return Text(texto, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Widget _info(String t, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$t: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(v ?? "—")),
        ],
      ),
    );
  }
}
