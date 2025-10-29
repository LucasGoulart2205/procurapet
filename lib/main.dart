import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Maps Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MapaTela(),
    );
  }
}

class MapaTela extends StatefulWidget {
  const MapaTela({super.key});

  @override
  State<MapaTela> createState() => _MapaTelaState();
}

class _MapaTelaState extends State<MapaTela> {
  late GoogleMapController mapaController;

  final LatLng _centro = const LatLng(-29.3333, -49.7333);

  void _aoCriarMapa(GoogleMapController controller) {
    mapaController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: GoogleMap(
        onMapCreated: _aoCriarMapa,
        initialCameraPosition: CameraPosition(
          target: _centro,
          zoom: 14.0,
        ),
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
