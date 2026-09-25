import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────
// Model Faskes dari OpenStreetMap
// ─────────────────────────────────────────────────────────
class FaskesItem {
  final String id;
  final String name;
  final String type;       // Kategori tampilan
  final String osmType;    // amenity value dari OSM
  final String status;
  final Color statusColor;
  final IconData icon;
  final LatLng position;
  double distanceMeters;

  FaskesItem({
    required this.id,
    required this.name,
    required this.type,
    required this.osmType,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.position,
    this.distanceMeters = 0,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  // Build dari elemen Overpass JSON
  factory FaskesItem.fromOverpass(Map<String, dynamic> el) {
    final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
    final lat = (el['lat'] as num?)?.toDouble() ??
        (el['center']?['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (el['lon'] as num?)?.toDouble() ??
        (el['center']?['lon'] as num?)?.toDouble() ?? 0.0;

    final amenity = tags['amenity']?.toString() ?? '';
    final healthcare = tags['healthcare']?.toString() ?? '';
    final rawName = tags['name']?.toString() ?? tags['name:id']?.toString() ?? '';
    final nameLower = rawName.toLowerCase();

    // Tentukan tipe & icon
    String type;
    IconData icon;
    String osmType = amenity.isNotEmpty ? amenity : healthcare;

    if (nameLower.contains('puskesmas') || nameLower.contains('pustu')) {
      type = 'Puskesmas';
      icon = Icons.home_work_rounded;
    } else if (amenity == 'hospital' ||
        healthcare == 'hospital' ||
        nameLower.contains('rumah sakit') ||
        nameLower.contains(' rs ') ||
        nameLower.startsWith('rs ') ||
        nameLower.contains('rsud') ||
        nameLower.contains('rsia') ||
        nameLower.contains('rsup')) {
      type = 'Rumah Sakit';
      icon = Icons.local_hospital_rounded;
    } else if (amenity == 'pharmacy' ||
        healthcare == 'pharmacy' ||
        nameLower.contains('apotek') ||
        nameLower.contains('farmasi') ||
        nameLower.contains('lab') ||
        amenity == 'laboratory' ||
        healthcare == 'laboratory') {
      type = 'Lab/Apotek';
      icon = Icons.local_pharmacy_rounded;
    } else if (amenity == 'dentist' || nameLower.contains('gigi')) {
      type = 'Klinik';
      icon = Icons.medical_services_rounded;
    } else {
      type = 'Klinik';
      icon = Icons.medical_services_rounded;
    }

    // Nama fallback
    String displayName = rawName;
    if (displayName.isEmpty) {
      displayName = _defaultNameForType(type);
    }

    // Status: gunakan opening_hours jika ada
    String status;
    Color statusColor;
    final oh = tags['opening_hours']?.toString() ?? '';
    if (oh == '24/7') {
      status = 'Buka 24 jam';
      statusColor = const Color(0xFF2E7D32);
    } else if (oh.isNotEmpty) {
      status = 'Lihat jam operasional';
      statusColor = const Color(0xFF1565C0);
    } else {
      status = 'Hubungi untuk info jam';
      statusColor = const Color(0xFF757575);
    }

    return FaskesItem(
      id: '${el['type']}_${el['id']}',
      name: displayName,
      type: type,
      osmType: osmType,
      status: status,
      statusColor: statusColor,
      icon: icon,
      position: LatLng(lat, lng),
    );
  }

  static String _defaultNameForType(String type) {
    switch (type) {
      case 'Puskesmas': return 'Puskesmas';
      case 'Rumah Sakit': return 'Rumah Sakit';
      case 'Lab/Apotek': return 'Apotek / Lab';
      default: return 'Klinik';
    }
  }
}

// ─────────────────────────────────────────────────────────
// Overpass API Service
// ─────────────────────────────────────────────────────────
class _OverpassService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';
  static const _radiusMeters = 5000; // 5 km

  static Future<List<FaskesItem>> fetchNearby(LatLng center) async {
    final lat = center.latitude;
    final lng = center.longitude;
    final r = _radiusMeters;

    // Query Overpass QL: cari semua fasilitas kesehatan dalam radius
    final query = '''
[out:json][timeout:30];
(
  node["amenity"="hospital"](around:$r,$lat,$lng);
  node["amenity"="clinic"](around:$r,$lat,$lng);
  node["amenity"="doctors"](around:$r,$lat,$lng);
  node["amenity"="pharmacy"](around:$r,$lat,$lng);
  node["amenity"="dentist"](around:$r,$lat,$lng);
  node["healthcare"="hospital"](around:$r,$lat,$lng);
  node["healthcare"="clinic"](around:$r,$lat,$lng);
  node["healthcare"="centre"](around:$r,$lat,$lng);
  node["healthcare"="doctor"](around:$r,$lat,$lng);
  node["healthcare"="pharmacy"](around:$r,$lat,$lng);
  node["name"~"[Pp]uskesmas",i](around:$r,$lat,$lng);
  way["amenity"="hospital"](around:$r,$lat,$lng);
  way["amenity"="clinic"](around:$r,$lat,$lng);
  way["healthcare"="hospital"](around:$r,$lat,$lng);
  way["name"~"[Pp]uskesmas",i](around:$r,$lat,$lng);
  way["name"~"[Rr]umah [Ss]akit",i](around:$r,$lat,$lng);
);
out center;
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      body: query,
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw Exception('Overpass API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>?) ?? [];

    final items = <FaskesItem>[];
    final seenNames = <String>{};

    for (final el in elements) {
      try {
        final item = FaskesItem.fromOverpass(el as Map<String, dynamic>);
        if (item.position.latitude == 0 && item.position.longitude == 0) continue;
        // Dedup berdasarkan nama
        final key = item.name.toLowerCase();
        if (seenNames.contains(key)) continue;
        seenNames.add(key);
        items.add(item);
      } catch (_) {
        continue;
      }
    }

    return items;
  }
}

// ─────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────
class NearestFacilityScreen extends StatefulWidget {
  const NearestFacilityScreen({super.key});

  @override
  State<NearestFacilityScreen> createState() => _NearestFacilityScreenState();
}

class _NearestFacilityScreenState extends State<NearestFacilityScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  String _selectedCategory = 'Semua';
  bool _showMap = true;
  String _searchQuery = '';

  LatLng? _userLocation;
  bool _loadingLocation = true;
  String _locationError = '';

  List<FaskesItem> _faskesList = [];
  bool _loadingFaskes = false;
  String _faskesError = '';

  FaskesItem? _selectedFaskes;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _categories = ['Semua', 'Puskesmas', 'RS', 'Klinik', 'Lab/Apotek'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    _init();
  }

  Future<void> _init() async {
    await _getUserLocation();
    if (_userLocation != null) {
      await _fetchFaskes();
    }
  }

  // ── GPS Lokasi User ─────────────────────────────────────
  Future<void> _getUserLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = '';
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Layanan lokasi tidak aktif. Aktifkan GPS.';
          _loadingLocation = false;
        });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak. Buka pengaturan untuk mengaktifkan.';
          _loadingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = ll;
        _loadingLocation = false;
      });
      _mapController.move(ll, 14.5);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: $e';
        _loadingLocation = false;
      });
    }
  }

  // ── Fetch Faskes dari Overpass ──────────────────────────
  Future<void> _fetchFaskes() async {
    if (_userLocation == null) return;
    setState(() {
      _loadingFaskes = true;
      _faskesError = '';
      _faskesList = [];
    });
    try {
      final items = await _OverpassService.fetchNearby(_userLocation!);
      if (!mounted) return;

      // Hitung jarak dari user ke setiap faskes
      final distCalc = const Distance();
      for (final f in items) {
        f.distanceMeters = distCalc.as(
          LengthUnit.Meter,
          _userLocation!,
          f.position,
        );
      }
      // Urutkan dari terdekat
      items.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      setState(() {
        _faskesList = items;
        _loadingFaskes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _faskesError = 'Gagal memuat data: $e';
        _loadingFaskes = false;
      });
    }
  }

  // ── Filter ──────────────────────────────────────────────
  List<FaskesItem> get _filtered {
    return _faskesList.where((f) {
      final matchCat = _selectedCategory == 'Semua' ||
          (_selectedCategory == 'RS' && f.type == 'Rumah Sakit') ||
          f.type == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery) ||
          f.type.toLowerCase().contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();
  }

  // ── Buka Google Maps navigasi ───────────────────────────
  Future<void> _openMapsRoute(FaskesItem faskes) async {
    final dest = faskes.position;
    String url;
    if (_userLocation != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${dest.latitude},${dest.longitude}';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _flyTo(FaskesItem f) {
    setState(() {
      _selectedFaskes = f;
      _showMap = true;
    });
    _mapController.move(f.position, 16.0);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryFilter(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    if (_showMap) _buildMap(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Tombol back
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFD81B60)),
            ),
          ),
          const SizedBox(width: 14),
          // Judul & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Faskes Terdekat',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF141414))),
                _buildStatusText(),
              ],
            ),
          ),
          // Tombol refresh
          InkWell(
            onTap: _loadingFaskes || _loadingLocation ? null : () => _init(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
              ),
              child: (_loadingLocation || _loadingFaskes)
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD81B60)),
                    )
                  : const Icon(Icons.my_location_rounded, size: 20, color: Color(0xFFD81B60)),
            ),
          ),
          const SizedBox(width: 8),
          // Toggle peta
          InkWell(
            onTap: () => setState(() => _showMap = !_showMap),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _showMap ? const Color(0xFFD81B60) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showMap ? const Color(0xFFD81B60) : const Color(0xFFF8BBD0),
                  width: 1.2,
                ),
              ),
              child: Icon(Icons.map_rounded, size: 20, color: _showMap ? Colors.white : const Color(0xFFD81B60)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (_loadingLocation) {
      return Text('Mendapatkan lokasi GPS…',
          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF9E9E9E)));
    }
    if (_locationError.isNotEmpty) {
      return Text(_locationError,
          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFE57373)),
          maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (_loadingFaskes) {
      return Text('Mencari faskes di sekitar Anda…',
          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF1565C0)));
    }
    if (_faskesList.isEmpty && _faskesError.isEmpty) {
      return Text('Lokasi ditemukan ✓',
          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF2E7D32)));
    }
    return Text('${_faskesList.length} faskes ditemukan dalam radius 5 km',
        style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF2E7D32)));
  }

  // ── Search bar ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF141414)),
          decoration: InputDecoration(
            hintText: 'Cari puskesmas, klinik, RS, apotek…',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9E9E9E)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD81B60), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9E9E9E)),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  // ── Filter chip ─────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selectedCategory == cat;
          return Padding(
            padding: EdgeInsets.only(right: i < _categories.length - 1 ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(colors: [Color(0xFFFF8DA1), Color(0xFFD81B60)]) : null,
                  color: sel ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? Colors.transparent : const Color(0xFFF8BBD0), width: 1.2),
                  boxShadow: sel ? [BoxShadow(color: const Color(0xFFD81B60).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(cat,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF424242))),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Peta Nyata OpenStreetMap ────────────────────────────
  Widget _buildMap() {
    final center = _userLocation ?? const LatLng(-6.2088, 106.8456); // Jakarta fallback
    final visibleMarkers = _filtered.take(50).toList();

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14.5,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          // Tile OSM
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dcare.app',
            maxZoom: 19,
          ),

          // Marker faskes nyata
          if (visibleMarkers.isNotEmpty)
            MarkerLayer(
              markers: visibleMarkers.map((f) => Marker(
                point: f.position,
                width: 40,
                height: 46,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedFaskes = f);
                    _showRouteSheet(f);
                  },
                  child: _buildMarkerWidget(f),
                ),
              )).toList(),
            ),

          // Titik lokasi user
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  width: 26,
                  height: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 3)],
                    ),
                  ),
                ),
              ],
            ),

          // Jumlah hasil
          if (!_loadingFaskes && _faskesList.isNotEmpty)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                ),
                child: Text(
                  '${_filtered.length} faskes',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFD81B60)),
                ),
              ),
            ),

          // Loading overlay
          if (_loadingFaskes)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.6),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD81B60), strokeWidth: 2.5),
                ),
              ),
            ),

          const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget(FaskesItem f) {
    final isSelected = _selectedFaskes?.id == f.id;
    final color = isSelected ? const Color(0xFFAD1457) : const Color(0xFFD81B60);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 38 : 30,
          height: isSelected ? 38 : 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(f.icon, color: Colors.white, size: isSelected ? 20 : 16),
        ),
        CustomPaint(size: const Size(10, 6), painter: _PinTail(color: color)),
      ],
    );
  }

  // ── Body: list atau state ───────────────────────────────
  Widget _buildBody() {
    // GPS belum dapat
    if (_loadingLocation) {
      return _buildCenterState(
        icon: Icons.gps_fixed_rounded,
        iconColor: const Color(0xFF1976D2),
        title: 'Mendapatkan lokasi GPS…',
        subtitle: 'Mohon tunggu sebentar',
        showLoader: true,
      );
    }
    if (_locationError.isNotEmpty) {
      return _buildCenterState(
        icon: Icons.location_off_rounded,
        iconColor: const Color(0xFFE57373),
        title: 'Lokasi tidak tersedia',
        subtitle: _locationError,
        actionLabel: 'Coba Lagi',
        onAction: _init,
      );
    }
    // Fetching data
    if (_loadingFaskes) {
      return _buildCenterState(
        icon: Icons.travel_explore_rounded,
        iconColor: const Color(0xFFD81B60),
        title: 'Mencari fasilitas kesehatan…',
        subtitle: 'Mengambil data dari OpenStreetMap',
        showLoader: true,
      );
    }
    // Error
    if (_faskesError.isNotEmpty) {
      return _buildCenterState(
        icon: Icons.cloud_off_rounded,
        iconColor: const Color(0xFFE57373),
        title: 'Gagal memuat data',
        subtitle: 'Periksa koneksi internet lalu coba lagi',
        actionLabel: 'Coba Lagi',
        onAction: _fetchFaskes,
      );
    }
    // Tidak ada hasil
    final list = _filtered;
    if (list.isEmpty && _faskesList.isNotEmpty) {
      return _buildCenterState(
        icon: Icons.search_off_rounded,
        iconColor: const Color(0xFFF8BBD0),
        title: 'Tidak ditemukan',
        subtitle: 'Coba filter atau kata kunci lain',
      );
    }
    if (list.isEmpty) {
      return _buildCenterState(
        icon: Icons.place_outlined,
        iconColor: const Color(0xFFF8BBD0),
        title: 'Tidak ada faskes ditemukan',
        subtitle: 'Tidak ada fasilitas kesehatan dalam radius 5 km',
        actionLabel: 'Coba Lagi',
        onAction: _fetchFaskes,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _FaskesCard(
        faskes: list[i],
        isSelected: _selectedFaskes?.id == list[i].id,
        onTap: () => _flyTo(list[i]),
        onRoute: () {
          _flyTo(list[i]);
          _showRouteSheet(list[i]);
        },
      ),
    );
  }

  Widget _buildCenterState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showLoader = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLoader)
              const CircularProgressIndicator(color: Color(0xFFD81B60), strokeWidth: 2.5)
            else
              Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF424242)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9E9E9E)),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRouteSheet(FaskesItem f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RouteBottomSheet(faskes: f, onRoute: () => _openMapsRoute(f)),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Kartu Faskes
// ─────────────────────────────────────────────────────────
class _FaskesCard extends StatelessWidget {
  final FaskesItem faskes;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRoute;

  const _FaskesCard({required this.faskes, required this.isSelected, required this.onTap, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFD81B60) : const Color(0xFFFCE4EC),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFD81B60).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ikon
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(faskes.icon, color: const Color(0xFFD81B60), size: 26),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faskes.name,
                          style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(faskes.type,
                          style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF757575))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(width: 7, height: 7,
                              decoration: BoxDecoration(color: faskes.statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(faskes.status,
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: faskes.statusColor),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Jarak + tombol
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place_rounded, size: 13, color: Color(0xFFD81B60)),
                      const SizedBox(width: 2),
                      Text(faskes.distanceLabel,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD81B60))),
                    ]),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onRoute,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF8DA1), Color(0xFFD81B60)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.near_me_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Rute', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Pin tail painter
// ─────────────────────────────────────────────────────────
class _PinTail extends CustomPainter {
  final Color color;
  _PinTail({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────
// Bottom Sheet Rute
// ─────────────────────────────────────────────────────────
class _RouteBottomSheet extends StatelessWidget {
  final FaskesItem faskes;
  final VoidCallback onRoute;
  const _RouteBottomSheet({required this.faskes, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFF8BBD0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(12)),
                child: Icon(faskes.icon, color: const Color(0xFFD81B60), size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(faskes.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF141414))),
              Text('${faskes.type} · ${faskes.distanceLabel}',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575))),
            ])),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FFF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: faskes.statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(child: Text(faskes.status,
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: faskes.statusColor))),
            ]),
          ),
          const SizedBox(height: 18),
          _row(Icons.directions_walk_rounded, 'Berjalan kaki', _walkTime()),
          const SizedBox(height: 10),
          _row(Icons.directions_car_rounded, 'Berkendara', _driveTime()),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); onRoute(); },
              icon: const Icon(Icons.near_me_rounded, size: 18),
              label: Text('Buka di Google Maps',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String time) {
    return Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFD81B60), size: 20)),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF424242))),
      const Spacer(),
      Text(time, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFD81B60))),
    ]);
  }

  String _walkTime() {
    final m = faskes.distanceMeters;
    if (m == 0) return '–';
    return '~${(m / 80).ceil()} menit';
  }

  String _driveTime() {
    final m = faskes.distanceMeters;
    if (m == 0) return '–';
    return '~${(m / 500).ceil()} menit';
  }
}
