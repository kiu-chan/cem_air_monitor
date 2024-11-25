import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final LatLng centerLocation = LatLng(21.592, 105.824);
  int? selectedMarkerIndex;
  Map<String, List<Map<String, dynamic>>> weatherDataByFactory = {};

  // Danh sách các nhà máy
  final List<Map<String, dynamic>> factories = [
    {
      'name': 'Công Ty Cổ Phần Xi Măng Cao Ngan',
      'location': LatLng(21.634056, 105.810696),
      'capacity': '150.000 - 200.000 tấn/năm',
      'phone': '(0208) 3820376'
    },
    {
      'name': 'Nhà Máy Xi Măng La Hiên',
      'location': LatLng(21.700259, 105.902989),
      'capacity': '730.000 tấn xi măng/năm',
      'phone': '(0208) 3829154'
    },
    {
      'name': 'Công ty TNHH MTV Xi măng Quang Sơn',
      'location': LatLng(21.699656, 105.880776),
      'capacity': '1,4 triệu tấn sản phẩm/năm',
      'phone': '(0208) 382 3228'
    },
    {
      'name': 'Công ty CP Xi măng Quân Triều',
      'location': LatLng(21.601527, 105.772542),
      'capacity': '1 triệu tấn xi măng/năm',
      'phone': ''
    },
    {
      'name': 'Nhà máy Xi măng Lưu Xá',
      'location': LatLng(21.563397, 105.854263),
      'capacity': '60.000 tấn/năm',
      'phone': ''
    },
  ];

  // Tạo lưới điểm phụ cho mỗi nhà máy
  List<LatLng> generateGridPoints(LatLng center, double radius, int count) {
    List<LatLng> points = [];
    double angleStep = 2 * math.pi / count;
    
    for (int i = 0; i < count; i++) {
      double angle = i * angleStep;
      double lat = center.latitude + radius * math.cos(angle);
      double lng = center.longitude + radius * math.sin(angle);
      
      // Giới hạn trong khu vực Thái Nguyên
      if (lat >= 21.5 && lat <= 21.8 && lng >= 105.7 && lng <= 106.0) {
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }

  @override
  void initState() {
    super.initState();
    fetchAllWeatherData();
  }

  Future<void> fetchAllWeatherData() async {
    for (var factory in factories) {
      LatLng location = factory['location'];
      List<LatLng> gridPoints = generateGridPoints(location, 0.02, 6);
      gridPoints.insert(0, location); // Thêm vị trí nhà máy vào đầu danh sách

      List<Map<String, dynamic>> weatherPoints = [];
      
      for (var point in gridPoints) {
        try {
          final response = await http.get(Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=${point.latitude}&lon=${point.longitude}&units=metric&appid=b5da2b01187e7f3c9d2d8aeffe7228d8'));
          
          if (response.statusCode == 200) {
            var data = json.decode(response.body);
            weatherPoints.add({
              'location': point,
              'wind_speed': data['wind']['speed'],
              'wind_deg': data['wind']['deg'],
            });
          }
          // Đợi 1 giây giữa các request để tránh vượt quá giới hạn API
          // await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('Error fetching weather data: $e');
        }
      }

      setState(() {
        weatherDataByFactory[factory['name']] = weatherPoints;
      });
    }
  }

  Widget buildWindDirectionMarker(double degree, double speed, {bool isFactory = false}) {
    return Transform.rotate(
      angle: (degree * math.pi) / 180,
      child: CustomPaint(
        size: Size(isFactory ? 40 : 20, isFactory ? 40 : 20),
        painter: WindArrowPainter(
          color: _getWindSpeedColor(speed),
          isFactory: isFactory,
        ),
      ),
    );
  }

  Color _getWindSpeedColor(double speed) {
    if (speed < 0.5) return Colors.green.withOpacity(0.8);
    if (speed < 2) return Colors.blue.withOpacity(0.8);
    if (speed < 4) return Colors.orange.withOpacity(0.8);
    return Colors.red.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ các nhà máy Xi măng Thái Nguyên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllWeatherData,
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
          // Wind direction markers
          MarkerLayer(
            markers: [
              // Hiển thị markers cho các điểm gió
              ...weatherDataByFactory.entries.expand((entry) {
                return entry.value.map((weatherPoint) {
                  bool isFactory = weatherPoint['location'] == factories.firstWhere(
                    (f) => f['name'] == entry.key
                  )['location'];
                  
                  return Marker(
                    point: weatherPoint['location'],
                    width: isFactory ? 40 : 20,
                    height: isFactory ? 40 : 20,
                    child: buildWindDirectionMarker(
                      weatherPoint['wind_deg'].toDouble(),
                      weatherPoint['wind_speed'].toDouble(),
                      isFactory: isFactory,
                    ),
                  );
                }).toList();
              }).toList(),
              
              // Factory information markers
              ...List.generate(
                factories.length,
                (index) => Marker(
                  point: factories[index]['location'],
                  width: 200,
                  height: 150,
                  child: selectedMarkerIndex == index
                    ? Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factories[index]['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (factories[index]['capacity'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Công suất: ${factories[index]['capacity']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                            if (factories[index]['phone'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'SĐT: ${factories[index]['phone']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                            if (weatherDataByFactory.containsKey(factories[index]['name'])) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Gió: ${weatherDataByFactory[factories[index]['name']]?.first['wind_speed'].toStringAsFixed(1)} m/s',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Hướng: ${weatherDataByFactory[factories[index]['name']]?.first['wind_deg'].toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMarkerIndex = selectedMarkerIndex == index ? null : index;
                          });
                        },
                        child: const Icon(
                          Icons.factory,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                ),
              ),
            ],
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

class WindArrowPainter extends CustomPainter {
  final Color color;
  final bool isFactory;

  WindArrowPainter({
    required this.color,
    this.isFactory = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    // Draw arrow
    path.moveTo(size.width * 0.5, 0); // Top point
    path.lineTo(size.width * 0.8, size.height * 0.8); // Bottom right
    path.lineTo(size.width * 0.5, size.height * 0.6); // Middle indent
    path.lineTo(size.width * 0.2, size.height * 0.8); // Bottom left
    path.close();

    if (isFactory) {
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.fill;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}