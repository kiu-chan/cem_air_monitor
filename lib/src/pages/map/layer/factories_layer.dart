// factories_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'wind_direction_layer.dart';

class FactoriesLayer extends StatelessWidget {
  final int? selectedMarkerIndex;
  final Function(int) onMarkerTap;

  const FactoriesLayer({
    Key? key,
    required this.selectedMarkerIndex,
    required this.onMarkerTap,
  }) : super(key: key);

  static const List<Map<String, dynamic>> factories = [
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

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: List.generate(
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
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => onMarkerTap(index),
                  child: const Icon(
                    Icons.factory,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }
}