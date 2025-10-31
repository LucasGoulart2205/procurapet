import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'add_pet.dart';
import 'pet_details.dart';

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

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoAtual();
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
        const SnackBar(content: Text('Permissão de localização negada permanentemente.')),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets_rounded, color: Colors.black87, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Adicionar pet perdido?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Deseja adicionar um pet perdido neste local?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black26),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Adicionar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (adicionar == true) {
      final petInfo = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddPetScreen(local: posicao)),
      );

      if (petInfo != null) {
        final id = DateTime.now().toString();
        _petsInfo[id] = petInfo;

        setState(() {
          _marcadores.add(
            Marker(
              markerId: MarkerId(id),
              position: posicao,
              infoWindow: InfoWindow(
                title: petInfo['nome'],
                snippet: petInfo['especie'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PetDetailsScreen(petInfo: petInfo)),
                  );
                },
              ),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _localizacaoAtual == null
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
      ),
    );
  }
}
