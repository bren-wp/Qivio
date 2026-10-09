import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_store.dart';
import '../ui/qrex_theme.dart';
import 'result_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.store, this.openGalleryInitially = false});
  final AppStore store;
  final bool openGalleryInitially;
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  final MobileScannerController _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handling = false;
  bool _torchOn = false;
  double _zoom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openGalleryInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fromGallery();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_camera.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !_handling) {
      _camera.start().catchError((Object _) {});
    } else if (state == AppLifecycleState.inactive) {
      _camera.stop().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onCapture(BarcodeCapture capture) async {
    if (_handling) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        await _showResult(raw);
        break;
      }
    }
  }

  Future<void> _showResult(String raw) async {
    if (_handling || !mounted) return;
    _handling = true;
    try {
      await _camera.stop();
      await widget.store.record(raw);
      if (!mounted) return;
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => ResultPage(store: widget.store, raw: raw),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skeniranje nije uspjelo. Pokušaj ponovno.')));
      }
    } finally {
      _handling = false;
      if (mounted) {
        try { await _camera.start(); } catch (_) { /* Camera may be unavailable. */ }
      }
    }
  }

  Future<void> _fromGallery() async {
    if (_handling) return;
    try {
      final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (selected == null || !mounted) return;
      final result = await _camera.analyzeImage(selected.path);
      if (!mounted) return;
      final match = result?.barcodes.where((e) => e.rawValue?.isNotEmpty == true).firstOrNull;
      if (match?.rawValue != null) {
        await _showResult(match!.rawValue!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Na slici nije pronađen QR kod.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sliku nije moguće otvoriti.')));
      }
    }
  }

  Future<void> _setZoom(double zoom) async {
    try {
      await _camera.setZoomScale(zoom);
      if (mounted) setState(() => _zoom = zoom);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zumiranje nije dostupno na ovom uređaju.')));
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _camera.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Svjetiljka nije dostupna na ovom uređaju.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      MobileScanner(
        controller: _camera,
        onDetect: _onCapture,
        fit: BoxFit.cover,
        errorBuilder: (context, error) => Container(
          color: QrexPalette.base,
          child: const Center(child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.no_photography_outlined, size: 54, color: QrexPalette.muted),
              SizedBox(height: 16),
              Text('Dopusti pristup kameri u postavkama uređaja.', textAlign: TextAlign.center),
            ]),
          )),
        ),
      ),
      const IgnorePointer(child: _ScannerShade()),
      SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(children: [
            IconButton.filledTonal(
              tooltip: 'Svjetiljka',
              onPressed: _toggleTorch,
              icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            ),
            const Expanded(child: Center(child: QrexWordmark(small: true))),
            IconButton.filledTonal(
              tooltip: 'Skeniraj iz fotografije',
              onPressed: _fromGallery,
              icon: const Icon(Icons.photo_library_outlined),
            ),
          ]),
        ),
        const Spacer(),
        const _ScanCorners(),
        const SizedBox(height: 20),
        Semantics(label: 'Zum kamere', child: Container(
          decoration: BoxDecoration(color: const Color(0xD9091428),
            border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final zoom in [0.0, 0.5, 1.0])
              Padding(padding: const EdgeInsets.all(3), child: InkWell(
                borderRadius: BorderRadius.circular(30), onTap: () => _setZoom(zoom),
                child: Container(width: 50, height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _zoom == zoom ? QrexPalette.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(30)),
                  child: Text(zoom == 0 ? '1×' : zoom == .5 ? '2×' : 'Max',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              )),
          ]),
        )),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xD9091428),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text('Usmjeri kameru prema QR kodu', style: TextStyle(color: Colors.white)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: TextButton.icon(
            onPressed: _fromGallery,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Skeniraj iz slike'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ),
      ])),
    ]);
  }
}

class _ScannerShade extends StatelessWidget {
  const _ScannerShade();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xE0030C1B), Colors.transparent, Colors.transparent, const Color(0xD9030C1B)],
      stops: const [0, .30, .68, 1],
    )),
  );
}

class _ScanCorners extends StatelessWidget {
  const _ScanCorners();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final size = (MediaQuery.sizeOf(context).width * .72).clamp(200.0, 325.0);
    return SizedBox(
      height: size, width: size,
      child: CustomPaint(painter: _CornersPainter()),
    );
  });
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF58B9FF)..strokeWidth = 5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const edge = 38.0;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, edge)..lineTo(0, 18)..quadraticBezierTo(0, 0, 18, 0)..lineTo(edge, 0)
      ..moveTo(w - edge, 0)..lineTo(w - 18, 0)..quadraticBezierTo(w, 0, w, 18)..lineTo(w, edge)
      ..moveTo(0, h - edge)..lineTo(0, h - 18)..quadraticBezierTo(0, h, 18, h)..lineTo(edge, h)
      ..moveTo(w - edge, h)..lineTo(w - 18, h)..quadraticBezierTo(w, h, w, h - 18)..lineTo(w, h - edge);
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(8, h / 2), Offset(w - 8, h / 2),
      Paint()..shader = const LinearGradient(colors: [QrexPalette.cyan, QrexPalette.purple])
        .createShader(Rect.fromLTWH(0, h / 2, w, 1))..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
