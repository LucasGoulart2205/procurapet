import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPetScreen extends StatefulWidget {
  final LatLng local;
  const AddPetScreen({super.key, required this.local});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  String? _especieSelecionada;
  String? _sexoSelecionado;
  String? _porteSelecionado;

  final List<String> _especies = [
    'Cachorro',
    'Gato',
    'Pássaro',
    'Hamster',
    'Coelho',
    'Tartaruga',
    'Cobra'
  ];
  final List<String> _sexos = ['Macho', 'Fêmea'];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande'];

  bool _carregando = false;

  File? _imagemSelecionada;

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<void> _adicionarPet() async {
    if (_nomeController.text.isEmpty || _especieSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha ao menos o nome e a espécie')),
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
            .child('pets')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imagemSelecionada!);
        urlImagem = await ref.getDownloadURL();
      }

      final doc = await FirebaseFirestore.instance.collection('pets').add({
        'nome': _nomeController.text,
        'especie': _especieSelecionada,
        'raca': _racaController.text,
        'idade': _idadeController.text,
        'peso': _pesoController.text,
        'porte': _porteSelecionado,
        'cor': _corController.text,
        'sexo': _sexoSelecionado,
        'descricao': _descricaoController.text,
        'latitude': widget.local.latitude,
        'longitude': widget.local.longitude,
        'userId': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'imagemUrl': urlImagem,
      });

      Navigator.pop(context, {
        "id": doc.id,
        "data": {
          'nome': _nomeController.text,
          'especie': _especieSelecionada,
          'raca': _racaController.text,
          'idade': _idadeController.text,
          'peso': _pesoController.text,
          'porte': _porteSelecionado,
          'cor': _corController.text,
          'sexo': _sexoSelecionado,
          'descricao': _descricaoController.text,
          'latitude': widget.local.latitude,
          'longitude': widget.local.longitude,
          'imagemUrl': urlImagem,
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar pet: $e')),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Pet Perdido'),
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
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imagemSelecionada != null
                        ? Image.file(_imagemSelecionada!, fit: BoxFit.cover)
                        : const Center(child: Text('Toque para escolher uma foto')),
                  ),
                ),
                const SizedBox(height: 14),
                _campoTexto(_nomeController, 'Nome do Pet'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Espécie',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _especieSelecionada,
                  items: _especies
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _especieSelecionada = v),
                ),
                const SizedBox(height: 14),
                _campoTexto(_racaController, 'Raça'),
                const SizedBox(height: 14),
                _campoTexto(_idadeController, 'Idade'),
                const SizedBox(height: 14),
                _campoTexto(_pesoController, 'Peso'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Porte',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _porteSelecionado,
                  items: _portes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _porteSelecionado = v),
                ),
                const SizedBox(height: 14),
                _campoTexto(_corController, 'Cor'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sexo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _sexoSelecionado,
                  items: _sexos
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _sexoSelecionado = v),
                ),
                const SizedBox(height: 14),
                _campoTexto(_descricaoController, 'Descrição'),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _adicionarPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
