import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar data e hora

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> evento;

  const EventDetailsScreen({super.key, required this.evento});

  String formatarData(String? isoData) {
    if (isoData == null) return "";
    try {
      DateTime dt = DateTime.parse(isoData);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return isoData;
    }
  }

  String formatarHora(String? hora) {
    if (hora == null || hora.isEmpty) return "";
    return hora; // Já vem no formato HH:mm do cadastro
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Evento"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: evento['imagemUrl'] != null
                  ? Image.network(
                evento['imagemUrl'],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    "Sem foto",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              evento['nome'] ?? "Evento",
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (evento['local'] != null && evento['local'] != "")
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      evento['local'],
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.event, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  formatarData(evento['data']),
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  "${formatarHora(evento['horaInicio'])} - ${formatarHora(evento['horaFim'])}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Descrição",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              evento['descricao'] ?? "Nenhuma descrição informada.",
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
