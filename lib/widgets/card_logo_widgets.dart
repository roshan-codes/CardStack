import 'package:flutter/material.dart';

/// Renders a realistic golden EMV Chip
class EmvChipWidget extends StatelessWidget {
  const EmvChipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8CA72), Color(0xFFC7982E), Color(0xFFE5C568)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner circuit lines
          Center(
            child: Container(
              width: 32,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8C6414), width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 1,
              height: 22,
              color: const Color(0xFF8C6414),
            ),
          ),
          Center(
            child: Container(
              width: 32,
              height: 1,
              color: const Color(0xFF8C6414),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the contactless wave icon ((((
class ContactlessWaveWidget extends StatelessWidget {
  final Color color;

  const ContactlessWaveWidget({super.key, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _ContactlessPainter(color),
    );
  }
}

class _ContactlessPainter extends CustomPainter {
  final Color color;

  _ContactlessPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.1, size.height * 0.5);

    // 3 arcs
    for (int i = 1; i <= 3; i++) {
      final radius = 6.0 * i;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -0.6, 1.2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders Mastercard logo with overlapping red & orange circles
class MastercardLogo extends StatelessWidget {
  final double size;

  const MastercardLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final circleRadius = size * 0.44;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size * 1.5,
          height: size,
          child: Stack(
            children: [
              // Red circle (left)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: circleRadius * 2,
                  height: circleRadius * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB001B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Yellow/Orange circle (right)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: circleRadius * 2,
                  height: circleRadius * 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF79E1B).withOpacity(0.92),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'mastercard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Renders Visa Logo
class VisaLogo extends StatelessWidget {
  final double height;

  const VisaLogo({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'VISA',
        style: TextStyle(
          color: const Color(0xFF1A1F71),
          fontSize: height * 0.75,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Renders RuPay Logo
class RupayLogo extends StatelessWidget {
  final double height;

  const RupayLogo({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RuPay',
            style: TextStyle(
              color: const Color(0xFF0F4392),
              fontSize: height * 0.7,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 4,
            height: height * 0.7,
            color: const Color(0xFFF37021),
          ),
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: height * 0.7,
            color: const Color(0xFF00A651),
          ),
        ],
      ),
    );
  }
}

/// Renders American Express Logo
class AmexLogo extends StatelessWidget {
  final double height;

  const AmexLogo({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF006FCF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'AMEX',
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.65,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Renders Discover Logo
class DiscoverLogo extends StatelessWidget {
  final double height;

  const DiscoverLogo({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DISC',
            style: TextStyle(
              color: const Color(0xFF231F20),
              fontSize: height * 0.65,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            width: height * 0.5,
            height: height * 0.5,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6000),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            'VER',
            style: TextStyle(
              color: const Color(0xFF231F20),
              fontSize: height * 0.65,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dispatches the appropriate card network logo widget
class NetworkLogoDispatcher extends StatelessWidget {
  final String network;
  final double height;

  const NetworkLogoDispatcher({
    super.key,
    required this.network,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final net = network.trim().toLowerCase();
    if (net.contains('master')) {
      return MastercardLogo(size: height * 1.5);
    } else if (net.contains('visa')) {
      return VisaLogo(height: height);
    } else if (net.contains('rupay')) {
      return RupayLogo(height: height);
    } else if (net.contains('amex') || net.contains('american')) {
      return AmexLogo(height: height);
    } else if (net.contains('discover')) {
      return DiscoverLogo(height: height);
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          network.isNotEmpty ? network.toUpperCase() : 'CARD',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );
    }
  }
}

