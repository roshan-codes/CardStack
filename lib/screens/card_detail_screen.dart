import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import 'add_card_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;
  final ValueChanged<CardModel>? onCardUpdated;
  final ValueChanged<String>? onCardDeleted;

  const CardDetailScreen({
    super.key,
    required this.card,
    this.onCardUpdated,
    this.onCardDeleted,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late CardModel _card;
  bool _isCvvVisible = false;
  Timer? _clipboardClearTimer;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(String label, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));

    // Privacy & Security: Clear clipboard after 30 seconds so sensitive details are not left exposed
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 30), () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('$label copied to clipboard!'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteCard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Card'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_card.nickname}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_delete_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              widget.onCardDeleted?.call(_card.id);
              Navigator.of(context).pop(); // close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_card.nickname} deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEditCardScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCardScreen(
          initialCard: _card,
          onCardAdded: (updated) {
            setState(() {
              _card = updated;
            });
            widget.onCardUpdated?.call(updated);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Card updated successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final theme = Theme.of(context);
    final baseColor = card.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          card.nickname,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            key: const Key('card_detail_menu_button'),
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _openEditCardScreen();
              } else if (value == 'delete') {
                _confirmDeleteCard();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Card'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete Card', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    baseColor,
                    Color.lerp(baseColor, Colors.black, 0.28) ?? baseColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank Name & Card Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.bankName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            card.cardType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Chip and contactless
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card Number
                    Text(
                      card.cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 2.2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cardholder & Expiry
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.cardholderName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (card.formattedExpiry.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'EXPIRES',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.formattedExpiry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        Text(
                          card.cardNetwork,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Quick Copy Section
            Text(
              'Copy to Clipboard',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Copy Card Number
            _CopyTile(
              key: const Key('copy_number_tile'),
              icon: Icons.credit_card_rounded,
              label: 'Card Number',
              value: card.cardNumber,
              onCopy: () => _copyToClipboard('Card Number', card.cardNumber),
            ),
            const SizedBox(height: 10),

            // 2. Copy Expiry Date
            _CopyTile(
              key: const Key('copy_expiry_tile'),
              icon: Icons.calendar_today_rounded,
              label: 'Expiry Date',
              value: card.formattedExpiry.isNotEmpty
                  ? card.formattedExpiry
                  : 'N/A',
              onCopy: card.formattedExpiry.isNotEmpty
                  ? () => _copyToClipboard('Expiry Date', card.formattedExpiry)
                  : null,
            ),
            const SizedBox(height: 10),

            // 3. Copy CVV
            Builder(
              builder: (context) {
                final hasCvv = card.cvv != null && card.cvv!.trim().isNotEmpty;
                return _CopyTile(
                  key: const Key('copy_cvv_tile'),
                  icon: Icons.security_rounded,
                  label: 'CVV',
                  value: hasCvv
                      ? (_isCvvVisible ? card.cvv! : '•' * card.cvv!.length)
                      : 'Not Stored',
                  trailingAction: hasCvv
                      ? IconButton(
                          icon: Icon(
                            _isCvvVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: _isCvvVisible ? 'Hide CVV' : 'Show CVV',
                          onPressed: () {
                            setState(() {
                              _isCvvVisible = !_isCvvVisible;
                            });
                          },
                        )
                      : null,
                  onCopy: hasCvv
                      ? () => _copyToClipboard('CVV', card.cvv!)
                      : null,
                );
              },
            ),

            const SizedBox(height: 28),

            // Card Metadata Breakdown
            Text(
              'Card Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Bank', value: card.bankName),
                  const Divider(height: 20),
                  _DetailRow(
                      label: 'Type', value: card.cardType.toUpperCase()),
                  const Divider(height: 20),
                  _DetailRow(label: 'Network', value: card.cardNetwork),
                  const Divider(height: 20),
                  _DetailRow(label: 'Cardholder', value: card.cardholderName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailingAction;

  const _CopyTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction!,
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: 'Copy $label',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
