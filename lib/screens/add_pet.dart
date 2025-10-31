import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  String? _especieSelecionada;
  String? _sexoSelecionado;

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
      'altura': _alturaController.text,
      'cor': _corController.text,
      'sexo': _sexoSelecionado,
      'descricao': _descricaoController.text,
      'local': widget.local,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Pet Perdido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do pet'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Espécie'),
              value: _especieSelecionada,
              items: _especies
                  .map((esp) =>
                  DropdownMenuItem(value: esp, child: Text(esp)))
                  .toList(),
              onChanged: (valor) => setState(() {
                _especieSelecionada = valor;
              }),
            ),
            TextField(
              controller: _racaController,
              decoration: const InputDecoration(labelText: 'Raça'),
            ),
            TextField(
              controller: _idadeController,
              decoration: const InputDecoration(labelText: 'Idade (em anos)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _pesoController,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _alturaController,
              decoration: const InputDecoration(labelText: 'Altura (cm)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _corController,
              decoration: const InputDecoration(labelText: 'Cor'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Sexo'),
              value: _sexoSelecionado,
              items: _sexos
                  .map((sexo) =>
                  DropdownMenuItem(value: sexo, child: Text(sexo)))
                  .toList(),
              onChanged: (valor) => setState(() {
                _sexoSelecionado = valor;
              }),
            ),
            TextField(
              controller: _descricaoController,
              decoration:
              const InputDecoration(labelText: 'Descrição / Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _adicionarPet,
              child: const Text('Adicionar ao mapa'),
            ),
          ],
        ),
      ),
    );
  }
}
