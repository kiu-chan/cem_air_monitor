// wind_direction_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'factories_layer.dart';

class WindDirectionLayer extends StatefulWidget {
  final Function(int) onMarkerTap;

  const WindDirectionLayer({
    Key? key,
    required this.onMarkerTap,
  }) : super(key: key);

  @override
  WindDirectionLayerState createState() => WindDirectionLayerState();
}

class WindDirectionLayerState extends State<WindDirectionLayer> {
  Map<String, List<Map<String, dynamic>>> weatherDataByFactory = {};

  @override
  void initState() {
    super.initState();
    fetchAllWeatherData();
  }

  List<LatLng> generateGridPoints(LatLng center, double radius, int count) {
    List<LatLng> points = [];
    double angleStep = 2 * math.pi / count;
    
    for (int i = 0; i < count; i++) {
      double angle = i * angleStep;
      double lat = center.latitude + radius * math.cos(angle);
      double lng = center.longitude + radius * math.sin(angle);
      
      if (lat >= 21.5 && lat <= 21.8 && lng >= 105.7 && lng <= 106.0) {
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }

  Future<void> fetchAllWeatherData() async {
    for (var factory in FactoriesLayer.factories) {
      LatLng location = factory['location'];
      List<LatLng> gridPoints = generateGridPoints(location, 0.02, 6);
      gridPoints.insert(0, location);

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
        } catch (e) {
          print('Error fetching weather data: $e');
        }
      }

      if (mounted) {
        setState(() {
          weatherDataByFactory[factory['name']] = weatherPoints;
        });
      }
    }
  }

  Color _getWindSpeedColor(double speed) {
    if (speed < 0.5) return Colors.green.withOpacity(0.8);
    if (speed < 2) return Colors.blue.withOpacity(0.8);
    if (speed < 4) return Colors.orange.withOpacity(0.8);
    return Colors.red.withOpacity(0.8);
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

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: weatherDataByFactory.entries.expand((entry) {
        return entry.value.map((weatherPoint) {
          bool isFactory = weatherPoint['location'] == FactoriesLayer.factories.firstWhere(
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
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.8);
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