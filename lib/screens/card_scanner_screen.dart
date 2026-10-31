import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/card_model.dart';
import '../services/card_ocr_parser.dart';

class CardScannerScreen extends StatefulWidget {
  final ValueChanged<CardModel> onCardScanned;

  const CardScannerScreen({super.key, required this.onCardScanned});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasCameraError = false;
  bool _isFlashOn = false;

  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initCamera();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _hasCameraError = true;
          });
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasCameraError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isFlashOn = newFlash;
      });
    } catch (_) {}
  }

  /// Captures an image and processes OCR offline using on-device ML Kit
  Future<void> _captureAndScan() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_cameraController != null && _isCameraInitialized) {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        final lines = recognizedText.blocks
            .expand((b) => b.lines)
            .map((l) => l.text)
            .toList();

        final parsed = CardOcrParser.parse(lines);
        if (mounted) {
          _showConfirmationSheet(parsed);
        }
      } else {
        // Fallback demo card if on emulator or camera failed
        _simulateSampleScan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not scan card. Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _simulateSampleScan() {
    final sampleParsed = CardOcrParser.parse([
      'HDFC Bank',
      'Millennia Credit',
      '4532 9988 7766 1234',
      'VALID THRU 11/29',
      'RAHUL SHARMA',
      'VISA',
    ]);
    _showConfirmationSheet(sampleParsed);
  }

  void _showConfirmationSheet(ScannedCardData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScannedCardConfirmSheet(
        initialData: data,
        onConfirm: (newCard) {
          Navigator.of(ctx).pop(); // close sheet
          Navigator.of(context).pop(); // close scanner screen
          widget.onCardScanned(newCard);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.86;
    final cardHeight = cardWidth / 1.586; // standard card ratio

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Scan Payment Card'),
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Toggle Flash',
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview or Fallback
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: const Color(0xFF141922),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Offline Card Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasCameraError
                            ? 'Camera not accessible on this device.\nYou can simulate an offline card scan below.'
                            : 'Starting on-device offline camera scanner...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Dark overlay with cutout viewfinder
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder Border & Animated Scan Line
          Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: cardHeight * _scanAnimation.value,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align card edges inside the frame',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        key: const Key('capture_card_button'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _captureAndScan,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_rounded, size: 24),
                        label: Text(
                          _isProcessing ? 'Scanning Offline...' : 'Scan Card',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedCardConfirmSheet extends StatefulWidget {
  final ScannedCardData initialData;
  final ValueChanged<CardModel> onConfirm;

  const _ScannedCardConfirmSheet({
    required this.initialData,
    required this.onConfirm,
  });

  @override
  State<_ScannedCardConfirmSheet> createState() =>
      _ScannedCardConfirmSheetState();
}

class _ScannedCardConfirmSheetState extends State<_ScannedCardConfirmSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;
  late final TextEditingController _bankController;
  late final TextEditingController _numberController;
  late final TextEditingController _nameController;
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;

  final String _cardType = 'credit';
  String _cardNetwork = 'Visa';
  final String _colorHex = '#2455C3';

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _bankController =
        TextEditingController(text: d.bankName ?? 'HDFC Bank');
    _nicknameController = TextEditingController(
      text: d.bankName != null ? '${d.bankName} Card' : 'Scanned Card',
    );
    _numberController = TextEditingController(
      text: d.cardNumber ?? '4532 1234 5678 9012',
    );
    _nameController = TextEditingController(
      text: d.cardholderName ?? 'Rahul Sharma',
    );
    _expiryMonthController =
        TextEditingController(text: d.expiryMonth ?? '12');
    _expiryYearController =
        TextEditingController(text: d.expiryYear ?? '2029');
    _cardNetwork = d.cardNetwork ?? 'Visa';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bankController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newCard = CardModel(
      id: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
      nickname: _nicknameController.text.trim(),
      cardholderName: _nameController.text.trim(),
      bankName: _bankController.text.trim(),
      cardType: _cardType,
      cardNetwork: _cardNetwork,
      cardNumber: _numberController.text.trim(),
      expiryMonth: _expiryMonthController.text.trim().isEmpty
          ? null
          : _expiryMonthController.text.trim(),
      expiryYear: _expiryYearController.text.trim().isEmpty
          ? null
          : _expiryYearController.text.trim(),
      colorHex: _colorHex,
    );

    widget.onConfirm(newCard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Card Detected Offline',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Review details and save to your offline CardStack.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('scanned_number_field'),
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter card number' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bankController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter bank' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter nickname'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: _expiryMonthController,
                      decoration: const InputDecoration(
                        labelText: 'MM',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _expiryYearController,
                      decoration: const InputDecoration(
                        labelText: 'YY',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const Key('save_scanned_card_button'),
                  onPressed: _submit,
                  child: const Text(
                    'Save to CardStack',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
