import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:modern_go/core/constants/app_colors.dart';

class Particle {
  double x, y;
  double vx, vy;
  Color color;
  double radius;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double gravity) {
    x += vx;
    y += vy;
    vy += gravity;
    vx *= 0.98; // Air resistance
    vy *= 0.98;
    rotation += rotationSpeed;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  final double centerYOffset;

  ConfettiPainter({required this.particles, required this.centerYOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    canvas.save();
    // Translate coordinate system to center-top where checkmark is
    canvas.translate(size.width / 2, centerYOffset);

    for (final p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      
      // Draw rectangular confetti flake
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero, 
            width: p.radius * 2.5, 
            height: p.radius * 1.2
          ),
          Radius.circular(p.radius * 0.2),
        ),
        paint,
      );
      canvas.restore();
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CheckoutSuccessView extends StatefulWidget {
  final VoidCallback onDismiss;

  const CheckoutSuccessView({super.key, required this.onDismiss});

  @override
  State<CheckoutSuccessView> createState() => _CheckoutSuccessViewState();
}

class _CheckoutSuccessViewState extends State<CheckoutSuccessView> 
    with TickerProviderStateMixin {
  
  late final Ticker _ticker;
  final List<Particle> particles = [];
  final Random random = Random();

  // Animation Controllers
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  final double checkmarkYOffset = 180.0;

  // Statically initialized receipt details to prevent regeneration on tick rebuilds
  late final String transactionId;
  late final String dateString;

  @override
  void initState() {
    super.initState();

    transactionId = 'MG-${random.nextInt(900000) + 100000}';
    dateString = _getFormattedDate();

    // 1. Initialize Checkmark Scale Animation (elastic pop in)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 2. Initialize Receipt Card Slide/Fade Animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.decelerate,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    );

    // 3. Trigger Animations sequentially
    _scaleController.forward().then((_) {
      _slideController.forward();
    });

    // 4. Generate Confetti Flakes
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.pinkAccent,
      AppColors.primary,
    ];
    for (int i = 0; i < 90; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 3.0 + random.nextDouble() * 12.0;
      particles.add(Particle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 4.0, // initial upward force
        color: colors[random.nextInt(colors.length)],
        radius: 3.5 + random.nextDouble() * 4.5,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.3,
      ));
    }

    // 5. Start Physics Ticker for Confetti particles
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        for (final p in particles) {
          p.update(0.18); // gravity constant
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // ── CONFETTI LAYER ─────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(
                particles: particles,
                centerYOffset: checkmarkYOffset,
              ),
            ),
          ),

          // ── CONTENT LAYER ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Animated Checkmark Badge ─────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // ── Animated Slide-Up Receipt Card ───────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildReceiptCard(transactionId, dateString),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(String transactionId, String dateString) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            const Text(
              'Checkout Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thank you for your purchase at Modern Go',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 20),

            // Dashed Divider
            _buildDashedLine(),

            const SizedBox(height: 20),

            // Transaction Info
            _buildReceiptRow('Transaction ID', transactionId),
            _buildReceiptRow('Date', dateString),
            _buildReceiptRow('Payment Method', 'Saved Card (•••• 2345)'),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            _buildDashedLine(),

            const SizedBox(height: 30),

            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your digital receipt is ready',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A detailed breakdown has been saved to your account profile and sent to your email address.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[now.month - 1];
    final day = now.day.toString().padLeft(2, '0');
    final year = now.year;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$month $day, $year $hour:$minute';
  }
}
