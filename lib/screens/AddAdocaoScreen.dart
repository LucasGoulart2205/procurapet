import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddAdocaoScreen extends StatefulWidget {
  final LatLng local;
  const AddAdocaoScreen({super.key, required this.local});

  @override
  State<AddAdocaoScreen> createState() => _AddAdocaoScreenState();
}

class _AddAdocaoScreenState extends State<AddAdocaoScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicioSelecionada;
  TimeOfDay? _horaFimSelecionada;
  String? _voluntariosSelecionado;

  File? _imagemSelecionada;
  bool _carregando = false;

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() => _imagemSelecionada = File(imagem.path));
    }
  }

  Future<void> _selecionarData() async {
    DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHoraInicio() async {
    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaInicioSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => _horaInicioSelecionada = hora);
    }
  }

  Future<void> _selecionarHoraFim() async {
    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaFimSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => _horaFimSelecionada = hora);
    }
  }

  Future<void> _adicionarEvento() async {
    if (_nomeController.text.isEmpty || _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha ao menos nome e data')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não autenticado.");

      String? urlImagem;
      if (_imagemSelecionada != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('eventos')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imagemSelecionada!);
        urlImagem = await ref.getDownloadURL();
      }

      final doc = await FirebaseFirestore.instance.collection('adocoes').add({
        'nome': _nomeController.text,
        'descricao': _descricaoController.text,
        'data': _dataSelecionada?.toIso8601String(),
        'horaInicio': _horaInicioSelecionada?.format(context),
        'horaFim': _horaFimSelecionada?.format(context),
        'voluntarios': _voluntariosSelecionado,
        'latitude': widget.local.latitude,
        'longitude': widget.local.longitude,
        'userId': user.uid,
        'userName': user.displayName,
        'userPhoto': user.photoURL,
        'criadoEm': FieldValue.serverTimestamp(),
        'imagemUrl': urlImagem,
      });

      Navigator.pop(context, {
        "id": doc.id,
        "data": {
          'nome': _nomeController.text,
          'descricao': _descricaoController.text,
          'data': _dataSelecionada?.toIso8601String(),
          'horaInicio': _horaInicioSelecionada?.format(context),
          'horaFim': _horaFimSelecionada?.format(context),
          'voluntarios': _voluntariosSelecionado,
          'latitude': widget.local.latitude,
          'longitude': widget.local.longitude,
          'imagemUrl': urlImagem,
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar evento: $e')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  Widget _campoTexto(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _botaoData() {
    return ElevatedButton(
      onPressed: _selecionarData,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _dataSelecionada != null
            ? "${_dataSelecionada!.day.toString().padLeft(2,'0')}/"
            "${_dataSelecionada!.month.toString().padLeft(2,'0')}/"
            "${_dataSelecionada!.year}"
            : 'Selecionar Data',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _botaoHora(TimeOfDay? hora, String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        hora != null ? hora.format(context) : label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _dropdownVoluntarios() {
    return DropdownButtonFormField<String>(
      value: _voluntariosSelecionado,
      decoration: InputDecoration(
        labelText: "Voluntários",
        labelStyle: const TextStyle(color: Colors.teal),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'Sim', child: Text('Sim')),
        DropdownMenuItem(value: 'Não', child: Text('Não')),
      ],
      onChanged: (value) => setState(() => _voluntariosSelecionado = value),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Evento de Adoção'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selecionarImagem,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 1.2),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[200],
                    ),
                    child: _imagemSelecionada != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                    )
                        : const Center(
                      child: Text(
                        'Toque para escolher uma foto',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _campoTexto(_nomeController, 'Nome do Evento'),
                const SizedBox(height: 16),
                _campoTexto(_descricaoController, 'Descrição'),
                const SizedBox(height: 16),
                _botaoData(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _botaoHora(_horaInicioSelecionada, 'Hora Início', _selecionarHoraInicio)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _botaoHora(_horaFimSelecionada, 'Hora Fim', _selecionarHoraFim)),
                  ],
                ),
                const SizedBox(height: 16),
                _dropdownVoluntarios(),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _adicionarEvento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (_carregando)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
