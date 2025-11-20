import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'add_pet.dart';
import 'pet_details.dart';
import 'profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_ia.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapaController;
  LatLng? _localizacaoAtual;
  final Set<Marker> _marcadores = {};
  final Map<String, Map<String, dynamic>> _petsInfo = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoAtual();
    _carregarPetsDoFirestore();
  }

  Future<void> _obterLocalizacaoAtual() async {
    bool servicosAtivos = await Geolocator.isLocationServiceEnabled();
    if (!servicosAtivos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ative a localização.')),
      );
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) return;
    }

    if (permissao == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permissão de localização negada permanentemente.')),
      );
      return;
    }

    Position posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _localizacaoAtual = LatLng(posicao.latitude, posicao.longitude);
    });

    mapaController?.animateCamera(
      CameraUpdate.newLatLngZoom(_localizacaoAtual!, 15),
    );
  }

  Future<void> _carregarPetsDoFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pets').get();
      final Set<Marker> novosMarcadores = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final LatLng pos = LatLng(data['latitude'], data['longitude']);

        novosMarcadores.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: pos,
            infoWindow: InfoWindow(
              title: data['nome'] ?? 'Pet',
              snippet: data['especie'] ?? '',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PetDetailsScreen(
                      petInfo: data,
                      petId: doc.id,
                      onDeleted: _removerMarcador,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        _petsInfo[doc.id] = data;
      }

      setState(() {
        _marcadores.addAll(novosMarcadores);
      });
    } catch (e) {
      debugPrint("Erro ao carregar pets do Firestore: $e");
    }
  }

  void _removerMarcador(String petId) {
    setState(() {
      _marcadores.removeWhere((m) => m.markerId.value == petId);
      _petsInfo.remove(petId);
    });
  }

  void _aoCriarMapa(GoogleMapController controller) {
    mapaController = controller;
    if (_localizacaoAtual != null) {
      mapaController!.animateCamera(
        CameraUpdate.newLatLngZoom(_localizacaoAtual!, 15),
      );
    }
  }

  void _aoClicarNoMapa(LatLng posicao) async {
    final adicionar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets_rounded, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Adicionar pet perdido?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Deseja adicionar um pet perdido neste local?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (adicionar == true) {
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddPetScreen(local: posicao)),
      );

      if (resultado == null) return;

      final String id = resultado["id"];
      final Map<String, dynamic> data = resultado["data"];

      _petsInfo[id] = data;

      setState(() {
        _marcadores.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(data['latitude'], data['longitude']),
            infoWindow: InfoWindow(
              title: data['nome'],
              snippet: "${data['especie']} - ${data['porte']}",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PetDetailsScreen(
                      petInfo: data,
                      petId: id,
                      onDeleted: _removerMarcador,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      });
    }
  }

  Widget _buildMapScreen() {
    return _localizacaoAtual == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
      onMapCreated: _aoCriarMapa,
      initialCameraPosition: CameraPosition(
        target: _localizacaoAtual!,
        zoom: 15.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      markers: _marcadores,
      onTap: _aoClicarNoMapa,
    );
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildMapScreen();
      case 1:
        return const ChatIaScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _buildMapScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat IA"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
