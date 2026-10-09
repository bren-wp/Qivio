import 'package:flutter/material.dart';

class QrexPalette {
  static const base = Color(0xFF030C1B);
  static const surface = Color(0xFF101B2C);
  static const surfaceBright = Color(0xFF16253B);
  static const primary = Color(0xFF1677FF);
  static const cyan = Color(0xFF10C5FA);
  static const purple = Color(0xFF9047F8);
  static const muted = Color(0xFFADB9D0);
}

ThemeData qrexTheme(bool light) {
  final scheme = ColorScheme.fromSeed(
    seedColor: QrexPalette.primary,
    brightness: light ? Brightness.light : Brightness.dark,
    surface: light ? const Color(0xFFF3F6FF) : QrexPalette.base,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: light ? const Color(0xFFF3F6FF) : QrexPalette.base,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, centerTitle: true),
    cardTheme: CardThemeData(
      elevation: 0,
      color: light ? Colors.white : QrexPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? const Color(0xFFE8EEFA) : QrexPalette.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
    ),
  );
}

class QrexMark extends StatelessWidget {
  const QrexMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _QrexMarkPainter()),
  );
}

class _QrexMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * .23));
    final bg = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF00C8FF), Color(0xFF1268FF), Color(0xFF6D1CF3)],
    ).createShader(Offset.zero & size);
    canvas.drawRRect(r, bg);
    final white = Paint()..color = Colors.white..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .083..strokeCap = StrokeCap.round;
    final a = size.width * .22, b = size.width * .38, right = size.width * .78;
    final p = Path()
      ..moveTo(a, b)..lineTo(a, a + size.width * .085)..quadraticBezierTo(a, a, a + size.width * .085, a)..lineTo(b, a)
      ..moveTo(right - size.width * .16, a)..lineTo(right - size.width * .085, a)..quadraticBezierTo(right, a, right, a + size.width * .085)..lineTo(right, b)
      ..moveTo(a, right - size.width * .16)..lineTo(a, right - size.width * .085)..quadraticBezierTo(a, right, a + size.width * .085, right)..lineTo(b, right)
      ..moveTo(right - size.width * .16, right)..lineTo(right - size.width * .085, right)..quadraticBezierTo(right, right, right, right - size.width * .085)..lineTo(right, right - size.width * .16);
    canvas.drawPath(p, white);
    final center = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * .30, height: size.height * .30),
      Radius.circular(size.width * .045),
    );
    canvas.drawRRect(center, Paint()..color = const Color(0xFF73A4FD));
    canvas.drawRect(Rect.fromLTWH(size.width * .20, size.height * .48, size.width * .60, size.height * .035),
      Paint()..color = const Color(0xFFB4CBFF));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QrexWordmark extends StatelessWidget {
  const QrexWordmark({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    QrexMark(size: small ? 26 : 38), const SizedBox(width: 8),
    Text.rich(TextSpan(children: [
      TextSpan(text: 'QR', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      const TextSpan(text: 'EX', style: TextStyle(color: QrexPalette.primary)),
    ]), style: TextStyle(fontSize: small ? 22 : 31, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
  ]);
}

class QrexButton extends StatelessWidget {
  const QrexButton({super.key, required this.label, required this.onPressed, this.icon, this.secondary = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: const EdgeInsets.symmetric(vertical: 15), child:
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]));
    return SizedBox(width: double.infinity, child: secondary
        ? OutlinedButton(onPressed: onPressed, child: content)
        : FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(
            backgroundColor: QrexPalette.primary, foregroundColor: Colors.white), child: content));
  }
}
