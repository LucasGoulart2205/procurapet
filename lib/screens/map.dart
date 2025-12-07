import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// Telas do app
import 'add_pet.dart';
import 'pet_details.dart';
import 'profile.dart';
import 'chat_ia.dart';
import 'pets_list.dart';
// Import com alias para evitar conflito
import 'AddAdocaoScreen.dart' as addAdocao;
import 'event_details_screen.dart' as eventDetails;

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
    _carregarEventosDeAdocao();
  }

  // ================= Localização =================
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

  // ================= Marcadores Customizados =================
  Future<Uint8List> _getBytesFromUrl(String url, {int width = 100}) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<BitmapDescriptor> _createMarkerFromImage(String url,
      {int size = 150, Color borderColor = Colors.teal, double borderWidth = 5}) async {
    final Uint8List imageBytes = await _getBytesFromUrl(url, width: size);
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes, targetWidth: size, targetHeight: size);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..isAntiAlias = true;
    final double radius = size / 2;

    if (borderWidth > 0) {
      final Paint borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..isAntiAlias = true;

      canvas.drawCircle(Offset(radius, radius), radius - borderWidth / 2, borderPaint);
    }

    final Path clipPath = Path()..addOval(Rect.fromLTWH(borderWidth, borderWidth, size - 2 * borderWidth, size - 2 * borderWidth));
    canvas.clipPath(clipPath);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(borderWidth, borderWidth, size - 2 * borderWidth, size - 2 * borderWidth),
      paint,
    );

    final ui.Image finalImage = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // ================= Carregar Pets =================
  Future<void> _carregarPetsDoFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pets').get();
      final Set<Marker> novosMarcadores = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final LatLng pos = LatLng(data['latitude'], data['longitude']);

        BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
        if (data['imagemUrl'] != null) {
          icon = await _createMarkerFromImage(data['imagemUrl'], size: 120);
        }

        novosMarcadores.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: pos,
            icon: icon,
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

  // ================= Carregar Eventos =================
  Future<void> _carregarEventosDeAdocao() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('adocoes').get();
      final Set<Marker> eventosMarcadores = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final LatLng pos = LatLng(data['latitude'], data['longitude']);

        BitmapDescriptor icon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );

        if (data['imagemUrl'] != null) {
          icon = await _createMarkerFromImage(data['imagemUrl'], size: 130);
        }

        eventosMarcadores.add(
          Marker(
            markerId: MarkerId("evento_${doc.id}"),
            position: pos,
            icon: icon,
            infoWindow: InfoWindow(
              title: data['nome'] ?? "Evento de Adoção",
              snippet: data['local'] ?? "",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => eventDetails.EventDetailsScreen(
                      evento: {
                        ...data,
                        'id': doc.id,
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      setState(() {
        _marcadores.addAll(eventosMarcadores);
      });
    } catch (e) {
      print("Erro ao carregar eventos: $e");
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

  // ================= Clique no mapa =================
  void _aoClicarNoMapa(LatLng posicao) async {
    final opcao = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_location_alt_rounded, size: 48, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'O que deseja adicionar?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Escolha uma opção para adicionar neste local.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 8, // espaço horizontal entre os botões
                runSpacing: 8, // espaço vertical se quebrar
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, "cancelar"),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "evento"),
                    child: const Text('Evento'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "pet"),
                    child: const Text('Pet perdido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (opcao == null || opcao == "cancelar") return;

    if (opcao == "pet") {
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddPetScreen(local: posicao)),
      );

      if (resultado == null) return;

      final String id = resultado["id"];
      final doc = await FirebaseFirestore.instance.collection('pets').doc(id).get();
      final Map<String, dynamic> data = doc.data()!;

      _petsInfo[id] = data;

      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
      if (data['imagemUrl'] != null) {
        icon = await _createMarkerFromImage(data['imagemUrl'], size: 120);
      }

      setState(() {
        _marcadores.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(data['latitude'], data['longitude']),
            icon: icon,
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

    if (opcao == "evento") {
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => addAdocao.AddAdocaoScreen(local: posicao)),
      );

      if (resultado != null) {
        final id = resultado["id"];
        final data = resultado["data"];

        BitmapDescriptor icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        if (data['imagemUrl'] != null) {
          icon = await _createMarkerFromImage(data['imagemUrl'], size: 130);
        }

        setState(() {
          _marcadores.add(
            Marker(
              markerId: MarkerId("evento_$id"),
              position: LatLng(data['latitude'], data['longitude']),
              icon: icon,
              infoWindow: InfoWindow(
                title: data['nome'],
                snippet: data['local'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => eventDetails.EventDetailsScreen(evento: data),
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

  // ================= Build Map =================
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
        return const PetsListScreen();
      case 2:
        return const ChatIaScreen();
      case 3:
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Pets"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
