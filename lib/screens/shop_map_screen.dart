import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_center.dart';

class ShopMapScreen extends StatefulWidget {
  final ServiceCenter shop;

  const ShopMapScreen({super.key, required this.shop});

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  late GoogleMapController mapController;
  late LatLng _center;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.shop.latitude, widget.shop.longitude);
    _markers.add(
      Marker(
        markerId: MarkerId(widget.shop.id),
        position: _center,
        infoWindow: InfoWindow(
          title: widget.shop.name,
          snippet: widget.shop.address,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Map Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 16.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
          ),
          // Info Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name
                  Text(
                    widget.shop.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.shop.rating.toStringAsFixed(1)} (${widget.shop.reviewCount} reviews)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.shop.address,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.shop.tel.isNotEmpty ? widget.shop.tel : '전화번호 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=${widget.shop.latitude},${widget.shop.longitude}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('지도를 열 수 없습니다.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text("길찾기"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // 전화걸기 기능 구현 (추후)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('전화걸기 기능은 준비 중입니다.')),
                            );
                          },
                          icon: const Icon(Icons.call),
                          label: const Text("전화걸기"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}