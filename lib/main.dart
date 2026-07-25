import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const FleetSyncApp());
}

class FleetSyncApp extends StatelessWidget {
  const FleetSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FleetSync - Telemetry Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Contrôleur de Carte
  final MapController _mapController = MapController();

  // Données Télémétriques en direct
  LatLng _currentPosition = const LatLng(47.75, -3.36); // Position initiale (Lorient par défaut)
  double _currentSpeed = 0.0; // en km/h
  double _maxSpeed = 0.0;
  double _altitude = 0.0;
  double _heading = 0.0;
  double _totalDistance = 0.0; // en km

  // Tracking GPS
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      // Stopper le suivi
      _positionStreamSubscription?.cancel();
      setState(() => _isTracking = false);
    } else {
      // Démarrer le suivi GPS en temps réel
      setState(() {
        _isTracking = true;
        _routePoints.clear();
        _totalDistance = 0.0;
        _maxSpeed = 0.0;
      });

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        final newPoint = LatLng(position.latitude, position.longitude);
        final speedKmH = position.speed * 3.6; // m/s vers km/h

        setState(() {
          if (_routePoints.isNotEmpty) {
            final prevPoint = _routePoints.last;
            final addedMeters = Geolocator.distanceBetween(
              prevPoint.latitude,
              prevPoint.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
            _totalDistance += (addedMeters / 1000.0);
          }

          _currentPosition = newPoint;
          _routePoints.add(newPoint);
          _currentSpeed = speedKmH;
          if (speedKmH > _maxSpeed) _maxSpeed = speedKmH;
          _altitude = position.altitude;
          _heading = position.heading;
        });

        _mapController.move(newPoint, 16.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FleetSync Cockpit', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop_circle : Icons.play_circle_fill,
                color: _isTracking ? Colors.redAccent : Colors.greenAccent, size: 28),
            onPressed: _toggleTracking,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. CARTE OPENSTREETMAP (Partie supérieure)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fleetsync.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: Colors.cyanAccent,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 40,
                          height: 40,
                          child: Transform.rotate(
                            angle: (_heading * (pi / 180)),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.cyanAccent,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: () => _mapController.move(_currentPosition, 16.0),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),

          // 2. PANNEAU DE TÉLÉMÉTRIE & JAUGES (Partie inférieure)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF121824),
              child: Row(
                children: [
                  // Compteur de Vitesse Circulaire
                  Expanded(
                    flex: 4,
                    child: CustomPaint(
                      painter: SpeedometerPainter(speed: _currentSpeed, maxGaugeSpeed: 130),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentSpeed.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Text('KM/H', style: TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Grille d'indicateurs secondaires
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTelemetryCard('Distance Total', '${_totalDistance.toStringAsFixed(2)} km', Icons.route),
                        _buildTelemetryCard('Vitesse Max', '${_maxSpeed.toStringAsFixed(1)} km/h', Icons.speed),
                        _buildTelemetryCard('Altitude', '${_altitude.toStringAsFixed(0)} m', Icons.landscape),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

/* ========================================================================= */
/* DESSINATEUR SUR MESURE : COMPTEUR CIRCULAIRE (CustomPainter)              */
/* ========================================================================= */
class SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxGaugeSpeed;

  SpeedometerPainter({required this.speed, required this.maxGaugeSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    // Arc de fond
    final backgroundPaint = Paint()
      :color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5,
      false,
      backgroundPaint,
    );

    // Arc de vitesse actif
    final progress = (speed / maxGaugeSpeed).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed;
  }
}