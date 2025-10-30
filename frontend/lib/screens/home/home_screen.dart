import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/home_service.dart';
import '../../services/auth_service.dart';
import 'customer_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _bounceAnimation;
  int _selectedIndex = 0;

  static const Color primaryColor = Color(0xFF2474E5);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color primaryTextColor = Color(0xFF1A2525);
  static const Color secondaryTextColor = Color(0xFF607D8B);
  static const Color accentColor = Color(0xFFFFD333);
  static const Color whiteColor = Color(0xFFFFFFFF); // Trắng

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _animationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        );
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeInOut,
          ),
        );
        _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
          ),
        );
        _animationController!.forward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final homeService = Provider.of<HomeService>(context, listen: false);
        homeService.fetchHomeData(context);
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    if (index == 0) {
      // Đã ở Home, không cần làm gì
    } else if (index == 1) {
      // Không yêu cầu đăng nhập cho mục Tìm kiếm
      Navigator.pushReplacementNamed(context, '/trip/search');
    } else if (authService.currentUser == null) {
      Navigator.pushNamed(context, '/auth/login_prompt');
    } else {
      switch (index) {
        case 2:
          Navigator.pushReplacementNamed(context, '/tickets');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/auth/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Consumer2<HomeService, AuthService>(
          builder: (context, homeService, authService, _) {
            if (homeService.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }
            if (homeService.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      homeService.errorMessage!,
                      style: GoogleFonts.montserrat(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        homeService.fetchHomeData(context);
                      },
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (homeService.featuredTrips.isEmpty && homeService.locations.isEmpty) {
              return Center(
                child: Text(
                  'Không có dữ liệu để hiển thị.',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
              );
            }
            if (_fadeAnimation == null) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }
            return SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 45.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(55.0),
                          bottomRight: Radius.circular(55.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Chào mừng, ${authService.currentUser?.fullName ?? "Khách"}!',
                            style: GoogleFonts.montserrat(
                              color: whiteColor,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 120,
                            height: 6,
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Chúng tôi rất vinh dự được đồng hành cùng bạn trên mọi hành trình!',
                            style: GoogleFonts.montserrat(
                              color: whiteColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          AnimatedBuilder(
                            animation: _bounceAnimation!,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _bounceAnimation!.value,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/trip/search');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: Text(
                                    'Khám phá ngay',
                                    style: GoogleFonts.montserrat(
                                      color: primaryTextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Text(
                        'Chuyến đi nổi bật',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: homeService.featuredTrips.length > 3
                            ? 3
                            : homeService.featuredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = homeService.featuredTrips[index];
                          return FeaturedTripCard(
                            trip: trip,
                            primaryColor: primaryColor,
                            accentColor: accentColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Text(
                        'Địa điểm phổ biến',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    Container(
                      height: 170,
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: homeService.locations.length > 4
                            ? 4
                            : homeService.locations.length,
                        itemBuilder: (context, index) {
                          final location = homeService.locations[index];
                          return PopularLocationCard(
                            location: location,
                            primaryColor: primaryColor,
                            accentColor: accentColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class FeaturedTripCard extends StatefulWidget {
  final dynamic trip;
  final Color primaryColor;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const FeaturedTripCard({
    Key? key,
    required this.trip,
    required this.primaryColor,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  }) : super(key: key);

  @override
  _FeaturedTripCardState createState() => _FeaturedTripCardState();
}

class _FeaturedTripCardState extends State<FeaturedTripCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _translateAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -5),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: () {
          if (widget.trip.id.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/trip/detail/id',
              arguments: widget.trip.id,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chuyến đi không hợp lệ')),
            );
          }
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        borderRadius: BorderRadius.circular(16),
        splashColor: widget.primaryColor.withOpacity(0.3),
        highlightColor: widget.primaryColor.withOpacity(0.1),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _translateAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: widget.primaryColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.primaryColor.withOpacity(0.8),
                                widget.accentColor.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: FadeInImage(
                            placeholder: const AssetImage('assets/images/xe_u.jpg'),
                            image: const AssetImage('assets/images/xe_u.jpg'),
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 200),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.trip.departure_location} → ${widget.trip.arrival_location}',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: widget.primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Giá: ${widget.trip.price.toStringAsFixed(0)} VNĐ',
                              style: GoogleFonts.montserrat(
                                color: widget.accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PopularLocationCard extends StatefulWidget {
  final dynamic location;
  final Color primaryColor;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const PopularLocationCard({
    Key? key,
    required this.location,
    required this.primaryColor,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  }) : super(key: key);

  @override
  _PopularLocationCardState createState() => _PopularLocationCardState();
}

class _PopularLocationCardState extends State<PopularLocationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _translateAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -5),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/trip/search');
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        borderRadius: BorderRadius.circular(16),
        splashColor: widget.primaryColor.withOpacity(0.3),
        highlightColor: widget.primaryColor.withOpacity(0.1),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _translateAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: widget.primaryColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  color: Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          height: 170,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.primaryColor.withOpacity(0.8),
                                widget.accentColor.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: FadeInImage(
                            placeholder: const AssetImage('assets/images/google-maps-icon-on-map.jpg'),
                            image: const AssetImage('assets/images/google-maps-icon-on-map.jpg'),
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 200),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Text(
                            widget.location.location,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}