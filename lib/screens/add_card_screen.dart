import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../widgets/card_logo_widgets.dart';
import '../services/card_network_detector.dart';
import 'card_scanner_screen.dart';

class AddCardScreen extends StatefulWidget {
  final ValueChanged<CardModel> onCardAdded;

  const AddCardScreen({super.key, required this.onCardAdded});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _bankController = TextEditingController(text: 'MasterCard');

  String _detectedNetwork = 'Mastercard';
  Color _cardBgColor = const Color(0xFF0C1938);
  bool _manualOverride = false;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onNumberChanged);
    _nameController.addListener(() => setState(() {}));
    _expiryController.addListener(_onExpiryChanged);
    _cvvController.addListener(() => setState(() {}));
    _bankController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numberController.removeListener(_onNumberChanged);
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Color _colorForNetwork(String network) {
    final lower = network.toLowerCase();
    if (lower.contains('visa')) {
      return const Color(0xFF13274F);
    } else if (lower.contains('master')) {
      return const Color(0xFF0C1938);
    } else if (lower.contains('rupay')) {
      return const Color(0xFF003B46);
    } else if (lower.contains('amex') || lower.contains('american')) {
      return const Color(0xFF263238);
    } else if (lower.contains('discover')) {
      return const Color(0xFF4A2810);
    }
    return const Color(0xFF2C3E50);
  }

  void _onNumberChanged() {
    if (_manualOverride) return;

    final raw = _numberController.text.replaceAll(' ', '');
    final detected = CardNetworkDetector.detect(raw);
    String network = _detectedNetwork;
    Color color = _cardBgColor;

    if (!detected.isUnknown) {
      network = detected.name;
      color = _colorForNetwork(network);
    } else if (raw.isEmpty) {
      network = 'Mastercard';
      color = const Color(0xFF0C1938);
    } else {
      network = detected.name;
      color = const Color(0xFF2C3E50);
    }

    setState(() {
      _detectedNetwork = network;
      _cardBgColor = color;
      if (_bankController.text == 'MasterCard' && network == 'Visa') {
        _bankController.text = 'Visa Card';
      }
    });
  }

  void _onExpiryChanged() {
    setState(() {});
  }

  void _openCardScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardScannerScreen(
          onCardScanned: (scannedCard) {
            setState(() {
              _numberController.text = scannedCard.cardNumber;
              if (scannedCard.cardholderName.isNotEmpty &&
                  (_nameController.text.isEmpty ||
                      _nameController.text == 'Card Holder')) {
                _nameController.text = scannedCard.cardholderName;
              }
              if (scannedCard.expiryMonth != null &&
                  scannedCard.expiryYear != null) {
                final yy = scannedCard.expiryYear!.length == 4
                    ? scannedCard.expiryYear!.substring(2)
                    : scannedCard.expiryYear!;
                _expiryController.text = '${scannedCard.expiryMonth}/$yy';
              }
              if (scannedCard.bankName.isNotEmpty &&
                  (_bankController.text.isEmpty ||
                      _bankController.text == 'MasterCard')) {
                _bankController.text = scannedCard.bankName;
              }
            });
            _onNumberChanged();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Card number scanned from card!'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final number = _numberController.text.trim();
    final name = _nameController.text.trim().isEmpty
        ? 'Card Holder'
        : _nameController.text.trim();
    final bank = _bankController.text.trim().isEmpty
        ? _detectedNetwork
        : _bankController.text.trim();

    String? month;
    String? year;
    final expParts = _expiryController.text.trim().split('/');
    if (expParts.isNotEmpty) month = expParts[0];
    if (expParts.length > 1) {
      final y = expParts[1];
      year = y.length == 2 ? '20$y' : y;
    }

    final newCard = CardModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      nickname: '$bank $_detectedNetwork',
      cardholderName: name,
      bankName: bank,
      cardType: 'credit',
      cardNetwork: _detectedNetwork,
      cardNumber: number,
      expiryMonth: month,
      expiryYear: year,
      cvv: _cvvController.text.trim().isEmpty ? null : _cvvController.text.trim(),
      colorHex: '#${_cardBgColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );

    widget.onCardAdded(newCard);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Realtime preview card values
    final rawNumber = _numberController.text.trim();
    final displayNumber = rawNumber.isEmpty ? 'XXXX XXXX XXXX XXXX' : rawNumber;
    final displayName = _nameController.text.trim().isEmpty
        ? 'Card Holder'
        : _nameController.text.trim();
    final displayExpiry = _expiryController.text.trim().isEmpty
        ? '08/2022'
        : _expiryController.text.trim();
    final displayBank = _bankController.text.trim().isEmpty
        ? _detectedNetwork
        : _bankController.text.trim();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : Colors.white,
      appBar: AppBar(
        title: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Realtime Preview Card
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        _cardBgColor,
                        Color.lerp(_cardBgColor, Colors.black, 0.3) ?? _cardBgColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _cardBgColor.withOpacity(0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Bank Name and Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayBank,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          NetworkLogoDispatcher(network: _detectedNetwork),
                        ],
                      ),

                      // Middle Row: Chip + Contactless
                      const Row(
                        children: [
                          EmvChipWidget(),
                          SizedBox(width: 14),
                          ContactlessWaveWidget(),
                        ],
                      ),

                      // Card Number
                      Text(
                        displayNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          letterSpacing: 2.2,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Bottom Row: Cardholder + Valid Thru
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CARDHOLDER',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'VALID THRU',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayExpiry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Field 1: Card Number
                _InputField(
                  controller: _numberController,
                  hintText: 'Card Number',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    _CardNumberInputFormatter(),
                  ],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Tooltip(
                      message: 'Scan card number',
                      child: IconButton(
                        key: const Key('scan_card_number_button'),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            size: 19,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        onPressed: _openCardScanner,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.replaceAll(' ', '').length < 13) {
                      return 'Enter a valid 13-19 digit card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Network Detection Indicator / Manual Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        NetworkLogoDispatcher(
                          network: _detectedNetwork,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _detectedNetwork == 'Unknown'
                              ? 'Network: Unknown'
                              : (_manualOverride
                                  ? 'Network: $_detectedNetwork (Manual)'
                                  : 'Detected: $_detectedNetwork'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Select network manually',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _manualOverride ? 'Reset Auto' : 'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value == '__auto__') {
                            _manualOverride = false;
                            _onNumberChanged();
                          } else {
                            _manualOverride = true;
                            _detectedNetwork = value;
                            _cardBgColor = _colorForNetwork(value);
                          }
                        });
                      },
                      itemBuilder: (ctx) => [
                        if (_manualOverride)
                          const PopupMenuItem(
                            value: '__auto__',
                            child: Row(
                              children: [
                                Icon(Icons.auto_mode_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Auto-detect from number'),
                              ],
                            ),
                          ),
                        ...CardNetworkDetector.instance.networks.map(
                          (net) => PopupMenuItem(
                            value: net.name,
                            child: Row(
                              children: [
                                NetworkLogoDispatcher(network: net.name, height: 16),
                                const SizedBox(width: 10),
                                Text(net.name),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Field 2: Full Name
                _InputField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter cardholder name' : null,
                ),
                const SizedBox(height: 16),

                // Field 3 & 4: MM/YY and CVV
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _expiryController,
                        hintText: 'MM/YY',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateInputFormatter(),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().length < 4) {
                            return 'Enter MM/YY';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InputField(
                        controller: _cvvController,
                        hintText: 'CVV',
                        icon: Icons.lock_outline_rounded,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Field 5: Bank / Nickname
                _InputField(
                  controller: _bankController,
                  hintText: 'Bank Name (optional)',
                  icon: Icons.account_balance_outlined,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 36),

                // ADD CARD Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    key: const Key('submit_add_card_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'ADD CARD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2332) : const Color(0xFFF1F3F6),
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9EA3AE),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white54 : const Color(0xFF7E8494),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.8),
        ),
      ),
    );
  }
}

/// Formatter that inserts a space every 4 digits in card numbers
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter for MM/YY expiry
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
