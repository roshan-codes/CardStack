import 'package:flutter/material.dart';
import 'data/card_repository.dart';
import 'models/card_model.dart';
import 'screens/add_card_screen.dart';
import 'screens/auth_guard_screen.dart';
import 'screens/card_detail_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const CardStackApp());
}

class CardStackApp extends StatelessWidget {
  final AuthService? authService;
  final bool initiallyAuthenticated;
  final bool autoPromptAuth;

  const CardStackApp({
    super.key,
    this.authService,
    this.initiallyAuthenticated = false,
    this.autoPromptAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardStack',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2455C3),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2455C3),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F141C),
      ),
      builder: (context, child) {
        return AuthGuardScreen(
          authService: authService,
          initiallyAuthenticated: initiallyAuthenticated,
          autoPrompt: autoPromptAuth,
          child: child,
        );
      },
      home: const CardWalletScreen(),
    );
  }
}

class CardWalletScreen extends StatefulWidget {
  const CardWalletScreen({super.key});

  @override
  State<CardWalletScreen> createState() => _CardWalletScreenState();
}

class _CardWalletScreenState extends State<CardWalletScreen> {
  final CardRepository _repository = CardRepository();
  List<CardModel> _cards = CardRepository.getMockCards();
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final loaded = await _repository.loadCards();
    if (mounted) {
      setState(() {
        _cards = loaded;
      });
    }
  }

  int _countForFilter(String filter) {
    if (filter == 'All') return _cards.length;
    if (filter == 'Credit') {
      return _cards.where((c) => c.cardType.toLowerCase() == 'credit').length;
    }
    if (filter == 'Debit') {
      return _cards.where((c) => c.cardType.toLowerCase() == 'debit').length;
    }
    if (filter == 'Other') {
      return _cards
          .where((c) =>
              c.cardType.toLowerCase() != 'credit' &&
              c.cardType.toLowerCase() != 'debit')
          .length;
    }
    return 0;
  }

  List<CardModel> get _filteredCards {
    final query = _searchController.text.trim().toLowerCase();
    return _cards.where((c) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Credit' &&
              c.cardType.toLowerCase() == 'credit') ||
          (_selectedFilter == 'Debit' &&
              c.cardType.toLowerCase() == 'debit') ||
          (_selectedFilter == 'Other' &&
              c.cardType.toLowerCase() != 'credit' &&
              c.cardType.toLowerCase() != 'debit');

      final matchesSearch = query.isEmpty ||
          c.bankName.toLowerCase().contains(query) ||
          c.nickname.toLowerCase().contains(query) ||
          c.cardholderName.toLowerCase().contains(query) ||
          c.cardType.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _onAddCardManuallySelected() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCardScreen(
          onCardAdded: (newCard) {
            setState(() {
              _cards.insert(0, newCard);
            });
            _repository.addCard(newCard);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('${newCard.nickname} added!'),
                  ],
                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const filterTabs = ['All', 'Credit', 'Debit', 'Other'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row: "CardStack" and Blue "+" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.style_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      Text(
                        'CardStack',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: 'Add Card',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('add_card_appbar_button'),
                        onTap: _onAddCardManuallySelected,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Bar: "Search cards, bank or type..."
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF1E2638) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  key: const Key('bank_search_text_field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search cards, bank or type...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: const Color(0xFF9CA3AF),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // 3. Filter Pills: "All 6", "Credit 3", "Debit 2", "Other 1"
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: filterTabs.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final count = _countForFilter(filter);

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      key: Key('filter_tab_${filter.toLowerCase()}'),
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark
                                  ? const Color(0xFF1E2638)
                                  : const Color(0xFFF9FAFB)),
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF374151)),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : (isDark
                                        ? Colors.white38
                                        : const Color(0xFF9CA3AF)),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
                // Card list
                Expanded(
                  child: _filteredCards.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? 'No cards found for "${_searchController.text.trim()}"'
                                      : 'No cards found in this category.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCards.length,
                          itemBuilder: (context, index) {
                            final card = _filteredCards[index];
                            return _CardTile(
                              card: card,
                              onCardUpdated: (updated) {
                                setState(() {
                                  final idx =
                                      _cards.indexWhere((c) => c.id == updated.id);
                                  if (idx != -1) {
                                    _cards[idx] = updated;
                                  }
                                });
                                _repository.updateCard(updated);
                              },
                              onCardDeleted: (deletedId) {
                                setState(() {
                                  _cards.removeWhere((c) => c.id == deletedId);
                                });
                                _repository.deleteCard(deletedId);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardModel card;
  final ValueChanged<CardModel>? onCardUpdated;
  final ValueChanged<String>? onCardDeleted;

  const _CardTile({
    required this.card,
    this.onCardUpdated,
    this.onCardDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = card.cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.25) ?? baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(
                  card: card,
                  onCardUpdated: onCardUpdated,
                  onCardDeleted: onCardDeleted,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Bank name & Network / Type badge
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
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
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
            const SizedBox(height: 28),

            // Card chip & contactless icon
            Row(
              children: [
                Container(
                  width: 38,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.contactless_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Number
            Text(
              card.cardNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2.2,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Footer: Cardholder & Expiry
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
  ),
);
  }
}
