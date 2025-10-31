import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imagemSelecionada;

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

  final ImagePicker _picker = ImagePicker();

  // Função para selecionar imagem
  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  void _adicionarPet() {
    if (_nomeController.text.isEmpty || _especieSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha ao menos nome e espécie')),
      );
      return;
    }

    Navigator.pop(context, {
      'nome': _nomeController.text,
      'especie': _especieSelecionada,
      'raca': _racaController.text,
      'idade': _idadeController.text,
      'peso': _pesoController.text,
      'porte': _porteSelecionado,
      'cor': _corController.text,
      'sexo': _sexoSelecionado,
      'descricao': _descricaoController.text,
      'local': widget.local,
      'foto': _imagemSelecionada?.path, // envia o caminho da imagem
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Adicionar Pet Perdido',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              // Exibe a imagem selecionada
              GestureDetector(
                onTap: _selecionarImagem,
                child: _imagemSelecionada != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _imagemSelecionada!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Center(
                    child: Text(
                      'Toque para adicionar foto',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nomeController,
                decoration: _inputDecoration('Nome do pet'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Espécie'),
                value: _especieSelecionada,
                items: _especies
                    .map((esp) =>
                    DropdownMenuItem(value: esp, child: Text(esp)))
                    .toList(),
                onChanged: (valor) => setState(() {
                  _especieSelecionada = valor;
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _racaController,
                decoration: _inputDecoration('Raça'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _idadeController,
                decoration: _inputDecoration('Idade (em anos)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pesoController,
                decoration: _inputDecoration('Peso (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Porte'),
                value: _porteSelecionado,
                items: ['Pequeno', 'Médio', 'Grande']
                    .map((porte) =>
                    DropdownMenuItem(value: porte, child: Text(porte)))
                    .toList(),
                onChanged: (valor) => setState(() {
                  _porteSelecionado = valor;
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _corController,
                decoration: _inputDecoration('Cor'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Sexo'),
                value: _sexoSelecionado,
                items: _sexos
                    .map((sexo) =>
                    DropdownMenuItem(value: sexo, child: Text(sexo)))
                    .toList(),
                onChanged: (valor) => setState(() {
                  _sexoSelecionado = valor;
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descricaoController,
                decoration: _inputDecoration('Descrição / Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _adicionarPet,
                  child: const Text(
                    'Adicionar ao mapa',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
