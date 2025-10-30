import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/location_service.dart';
import '../../models/location.dart';

class LocationListScreen extends StatefulWidget {
  final String title;
  final String? initialLocationId;
  final bool isDeparture; // New parameter to determine if it's for departure or destination

  const LocationListScreen({
    super.key,
    this.title = 'Chọn Địa Điểm',
    this.initialLocationId,
    this.isDeparture = true, // Default to departure, adjust as needed
  });

  @override
  _LocationListScreenState createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Location> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    final locationService = Provider.of<LocationService>(context, listen: false);
    _filteredLocations = locationService.locations;
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    final locationService = Provider.of<LocationService>(context, listen: false);
    setState(() {
      _filteredLocations = locationService.locations
          .where((loc) => loc.location.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(
            context,
            '/trip/search',
          )
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF2474E5),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field attached to AppBar
          Container(
            color: const Color(0xFF2474E5), // Extend AppBar color
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tên tỉnh/thành phố, quận/huyện',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[300], fontWeight: FontWeight.w700),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2474E5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              style: GoogleFonts.poppins(),
            ),
          ),
          // Gap between search field and "Địa danh phổ biến"
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Địa danh phổ biến',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<LocationService>(
              builder: (context, locationService, _) {
                if (locationService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (locationService.locations.isEmpty) {
                  return Center(
                    child: Text(
                      'Không thể tải danh sách địa điểm.',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = _filteredLocations[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: widget.isDeparture
                              ? const Icon(
                            Icons.location_on, // Icon for departure
                            color: Color(0xFF2474E5),
                            size: 24,
                          )
                              : const Icon(
                            Icons.flag, // Icon for destination
                            color: Color(0xFF2474E5),
                            size: 24,
                          ),
                          title: Text(
                            location.location,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              'id': location.id,
                              'location': location.location,
                            });
                          },
                        ),
                        // Add divider except for the last item
                        if (index < _filteredLocations.length - 1)
                          Divider(
                            color: Colors.grey[300],
                            height: 1,
                            thickness: 1,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}