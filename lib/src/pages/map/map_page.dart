// map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'layer/factories_layer.dart';
import 'layer/wind_direction_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final LatLng centerLocation = LatLng(21.592, 105.824);
  int? selectedMarkerIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ các nhà máy Xi măng Thái Nguyên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (mounted) {
                setState(() {
                  // Trigger rebuild of child widgets
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              setState(() {
                selectedMarkerIndex = null;
              });
              mapController.move(centerLocation, 11.0);
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: centerLocation,
          initialZoom: 11.0,
          minZoom: 3.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onTap: (_, __) {
            setState(() {
              selectedMarkerIndex = null;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
            maxZoom: 18,
          ),
          WindDirectionLayer(
            onMarkerTap: (index) {
              setState(() {
                selectedMarkerIndex = index;
              });
            },
          ),
          FactoriesLayer(
            selectedMarkerIndex: selectedMarkerIndex,
            onMarkerTap: (index) {
              setState(() {
                selectedMarkerIndex = index;
              });
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                currentZoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                currentZoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}