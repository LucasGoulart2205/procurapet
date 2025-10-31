import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'add_pet.dart';
import 'pet_details.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapaController;
  final LatLng _centro = const LatLng(-29.3333, -49.7333);

  final Set<Marker> _marcadores = {};
  final Map<String, Map<String, dynamic>> _petsInfo = {};

  void _aoCriarMapa(GoogleMapController controller) {
    mapaController = controller;
  }

  void _aoClicarNoMapa(LatLng posicao) async {
    final adicionar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar pet perdido?'),
        content: const Text('Deseja adicionar um pet perdido neste local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (adicionar == true) {
      final petInfo = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPetScreen(local: posicao),
        ),
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
                    MaterialPageRoute(
                      builder: (_) => PetDetailsScreen(petInfo: petInfo),
                    ),
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
      body: GoogleMap(
        onMapCreated: _aoCriarMapa,
        initialCameraPosition: CameraPosition(
          target: _centro,
          zoom: 14.0,
        ),
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _marcadores,
        onTap: _aoClicarNoMapa,
      ),
    );
  }
}
