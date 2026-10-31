import 'widgets/liquid_glass_bar.dart';
import 'widgets/card_logo_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/neopop.dart';
import 'data/card_repository.dart';
import 'models/card_model.dart';
import 'screens/add_card_screen.dart';
import 'screens/auth_guard_screen.dart';
import 'screens/card_detail_screen.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';

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
    final lightBaseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2455C3),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
    );

    final darkBaseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2455C3),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F141C),
    );

    return MaterialApp(
      title: 'CardStack',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: lightBaseTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(lightBaseTheme.textTheme),
      ),
      darkTheme: darkBaseTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(darkBaseTheme.textTheme),
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
  final BackupService _backupService = BackupService();
  List<CardModel> _cards = [];
  String _selectedFilter = 'All';
  int _bottomNavIndex = 0;
  DateTime? _lastBackupTime;
  bool _isBackingUp = false;
  bool _biometricEnabled = true;
  bool _maskCardNumbers = true;
  bool _hapticFeedback = true;
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

  Future<void> _handleExportGoogleDrive() async {
    setState(() => _isBackingUp = true);
    final result = await _backupService.exportToGoogleDrive(_cards);
    if (mounted) {
      setState(() {
        _isBackingUp = false;
        if (result.success) {
          _lastBackupTime = DateTime.now();
        }
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor:
              result.success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRestoreGoogleDrive() async {
    setState(() => _isBackingUp = true);
    final result = await _backupService.restoreFromGoogleDrive();
    if (mounted) {
      if (result.success) {
        final reloaded = await _repository.loadCards();
        if (!mounted) return;
        setState(() {
          _cards = reloaded;
          _isBackingUp = false;
        });
      } else {
        setState(() => _isBackingUp = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor:
              result.success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const filterTabs = ['All', 'Credit', 'Debit', 'Other'];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0F141C) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: switch (_bottomNavIndex) {
          0 => _buildCardsView(theme, isDark, filterTabs),
          1 => _buildCategoryView(theme, isDark),
          2 => _buildBackupView(theme, isDark),
          3 => _buildSettingsView(theme, isDark),
          _ => _buildCardsView(theme, isDark, filterTabs),
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: LiquidGlassBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() => _bottomNavIndex = index);
          },
          style: LiquidGlassBarStyle(
            activeColor: const Color(0xFF2563EB),
            inactiveColor: isDark ? Colors.white60 : const Color(0xFF64748B),
            height: 60,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          ),
          items: const [
            LiquidGlassBarItem(
              iconData: Icons.home_rounded,
              label: 'Home',
            ),
            LiquidGlassBarItem(
              iconData: Icons.grid_view_rounded,
              label: 'Categories',
            ),
            LiquidGlassBarItem(
              iconData: Icons.cloud_upload_rounded,
              label: 'Backup',
            ),
            LiquidGlassBarItem(
              iconData: Icons.settings_rounded,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsView(
      ThemeData theme, bool isDark, List<String> filterTabs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Header Row: "CardStack" and Add Card Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(13),
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
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Text(
                    'CardStack',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: 'Add Card',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('add_card_fab'),
                    onTap: _onAddCardManuallySelected,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Search Bar with Filter Icon Button: "Search cards or banks..."
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('bank_search_text_field'),
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search cards or banks...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: const Color(0xFF94A3B8),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Filter Pills: "All 10", "Credit 5", "Debit 3", "Other 2"
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF1E2638) : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.32),
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
                                : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
                                  _cards.isEmpty
                                      ? Icons.credit_card_off_rounded
                                      : Icons.search_off_rounded,
                                  size: 56,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _cards.isEmpty
                                      ? 'No Cards in Vault'
                                      : (_searchController.text.trim().isNotEmpty
                                          ? 'No cards found for "${_searchController.text.trim()}"'
                                          : 'No cards found in this category.'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _cards.isEmpty
                                      ? 'Tap the + button below or scan your payment card to securely add your first card.'
                                      : 'Try clearing your search or switching filter categories.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_cards.isEmpty) ...[
                                  const SizedBox(height: 20),
                                  NeoPopButton(
                                    key: const Key('add_first_card_button'),
                                    color: const Color(0xFF2563EB),
                                    buttonPosition: Position.center,
                                    onTapUp: () {
                                      HapticFeedback.lightImpact();
                                      _onAddCardManuallySelected();
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'ADD YOUR FIRST CARD',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
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
    );
  }

  Widget _buildCategoryView(ThemeData theme, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    final creditCards =
        _cards.where((c) => c.cardType.toLowerCase() == 'credit').toList();
    final debitCards =
        _cards.where((c) => c.cardType.toLowerCase() == 'debit').toList();
    final prepaidCards =
        _cards.where((c) => c.cardType.toLowerCase() == 'prepaid').toList();
    final atmCards =
        _cards.where((c) => c.cardType.toLowerCase() == 'atm').toList();
    final otherCards = _cards.where((c) {
      final t = c.cardType.toLowerCase();
      return t != 'credit' && t != 'debit' && t != 'prepaid' && t != 'atm';
    }).toList();

    final categories = [
      _CategoryItemData(
        title: 'Credit Cards',
        cards: creditCards,
        gradient: const [Color(0xFFFF7A7A), Color(0xFFEF4444)],
        icon: Icons.credit_card_rounded,
      ),
      _CategoryItemData(
        title: 'Debit Cards',
        cards: debitCards,
        gradient: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
        icon: Icons.payment_rounded,
      ),
      _CategoryItemData(
        title: 'Prepaid Cards',
        cards: prepaidCards,
        gradient: const [Color(0xFF34D399), Color(0xFF059669)],
        icon: Icons.credit_card_outlined,
      ),
      _CategoryItemData(
        title: 'ATM Cards',
        cards: atmCards,
        gradient: const [Color(0xFFFB923C), Color(0xFFEA580C)],
        icon: Icons.local_atm_rounded,
      ),
      _CategoryItemData(
        title: 'Other Cards',
        cards: otherCards,
        gradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
        icon: Icons.wallet_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Categories title + Add (+) button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: titleColor,
                ),
              ),
              InkWell(
                key: const Key('add_card_category_button'),
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (_hapticFeedback) HapticFeedback.lightImpact();
                  _onAddCardManuallySelected();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Categories List
          ...categories.map((cat) {
            final count = cat.cards.length;
            final countText = '$count ${count == 1 ? 'card' : 'cards'}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    _openCategoryCardsSheet(cat.title, cat.cards, isDark),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Gradient squircle icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cat.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: cat.gradient.last.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            cat.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title & card count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              countText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openCategoryCardsSheet(
      String categoryTitle, List<CardModel> categoryCards, bool isDark) {
    if (_hapticFeedback) HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryTitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${categoryCards.length} ${categoryCards.length == 1 ? 'card' : 'cards'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: categoryCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_off_rounded,
                                size: 48,
                                color:
                                    isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text(
                              'No cards in $categoryTitle yet',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        itemCount: categoryCards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final card = categoryCards[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardDetailScreen(
                                    card: card,
                                    onCardUpdated: (updated) {
                                      setState(() {
                                        final idx = _cards.indexWhere(
                                            (c) => c.id == updated.id);
                                        if (idx != -1) _cards[idx] = updated;
                                      });
                                      _repository.updateCard(updated);
                                    },
                                    onCardDeleted: (deletedId) {
                                      setState(() {
                                        _cards.removeWhere(
                                            (c) => c.id == deletedId);
                                      });
                                      _repository.deleteCard(deletedId);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  NetworkLogoDispatcher(
                                    network: card.cardNetwork,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card.nickname,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${card.bankName} • ${card.cardNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupView(ThemeData theme, bool isDark) {
    final lastSyncText = _lastBackupTime != null
        ? '${_lastBackupTime!.hour.toString().padLeft(2, '0')}:${_lastBackupTime!.minute.toString().padLeft(2, '0')}'
        : 'Never';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Text(
                'Google Drive Backup',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Status / Vault Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_to_drive_rounded,
                      color: Color(0xFF2563EB),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Vault Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_cards.length} cards in vault  •  Last backup: $lastSyncText',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Option 1: Export to Google Drive
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_upload_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export to Google Drive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upload encrypted cards backup to Google Drive',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: NeoPopButton(
                    key: const Key('export_google_drive_button'),
                    color: const Color(0xFF2563EB),
                    buttonPosition: Position.center,
                    onTapUp: _isBackingUp ? null : _handleExportGoogleDrive,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isBackingUp) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Icon(Icons.cloud_upload_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          const Text(
                            'EXPORT TO GOOGLE DRIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Option 2: Restore from Google Drive
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_download_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore from Google Drive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Retrieve and sync your saved cards from Google Drive',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: NeoPopButton(
                    key: const Key('restore_google_drive_button'),
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFF0F172A),
                    buttonPosition: Position.center,
                    onTapUp: _isBackingUp ? null : _handleRestoreGoogleDrive,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isBackingUp) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Icon(Icons.cloud_download_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          const Text(
                            'RESTORE FROM GOOGLE DRIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Security & Encryption Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AES-256 Cloud Security: Your card numbers remain encrypted before uploading to Google Drive.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(ThemeData theme, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.settings_suggest_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Section 1: Security & Privacy
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SECURITY & PREFERENCES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: subtitleColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Biometric Unlock
                _buildSettingSwitchTile(
                  switchKey: const Key('setting_biometric_switch'),
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFF3B82F6).withOpacity(0.12),
                  title: 'Biometric Unlock',
                  subtitle: 'Require Face ID / Fingerprint on launch',
                  value: _biometricEnabled,
                  onChanged: (val) {
                    if (_hapticFeedback) HapticFeedback.selectionClick();
                    setState(() => _biometricEnabled = val);
                  },
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: borderColor, indent: 64),
                // 2. Mask Numbers
                _buildSettingSwitchTile(
                  switchKey: const Key('setting_mask_switch'),
                  icon: Icons.visibility_off_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBg: const Color(0xFF10B981).withOpacity(0.12),
                  title: 'Mask Sensitive Details',
                  subtitle: 'Hide full card number & CVV until tapped',
                  value: _maskCardNumbers,
                  onChanged: (val) {
                    if (_hapticFeedback) HapticFeedback.selectionClick();
                    setState(() => _maskCardNumbers = val);
                  },
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: borderColor, indent: 64),
                // 3. Haptic Feedback
                _buildSettingSwitchTile(
                  switchKey: const Key('setting_haptic_switch'),
                  icon: Icons.vibration_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.12),
                  title: 'Haptic Feedback',
                  subtitle: 'Tactile response on taps and card actions',
                  value: _hapticFeedback,
                  onChanged: (val) {
                    if (val) HapticFeedback.mediumImpact();
                    setState(() => _hapticFeedback = val);
                  },
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'CardStack v1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 12, color: subtitleColor.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Offline & On-Device Encrypted • AES-256',
                      style: TextStyle(
                        fontSize: 11,
                        color: subtitleColor.withOpacity(0.7),
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

  Widget _buildSettingSwitchTile({
    required Key switchKey,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            key: switchKey,
            value: value,
            activeColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CardWavePainter extends CustomPainter {
  final Color baseColor;

  const _CardWavePainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Upper-right organic curved wave
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(size.width * 0.42, 0);
    path1.cubicTo(
      size.width * 0.58,
      size.height * 0.25,
      size.width * 0.72,
      size.height * 0.48,
      size.width,
      size.height * 0.58,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Subtle curved contour stroke
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path2 = Path();
    path2.moveTo(size.width * 0.48, 0);
    path2.cubicTo(
      size.width * 0.62,
      size.height * 0.28,
      size.width * 0.76,
      size.height * 0.52,
      size.width,
      size.height * 0.65,
    );
    canvas.drawPath(path2, strokePaint);

    // Bottom-right darker curve
    final paint3 = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(size.width * 0.55, size.height);
    path3.cubicTo(
      size.width * 0.72,
      size.height * 0.78,
      size.width * 0.85,
      size.height * 0.62,
      size.width,
      size.height * 0.72,
    );
    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  List<Color> _resolveGradients(Color baseColor) {
    final hex = card.colorHex.toUpperCase();
    final bank = card.bankName.toLowerCase();

    if (hex == '#1E40AF' || bank.contains('hdfc')) {
      return const [Color(0xFF1D4ED8), Color(0xFF1E3A8A), Color(0xFF0F172A)];
    } else if (hex == '#DC2626' || bank.contains('icici')) {
      return const [Color(0xFFDC2626), Color(0xFFB91C1C), Color(0xFF7F1D1D)];
    } else if (hex == '#0F172A' || bank.contains('sbi')) {
      return const [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)];
    }

    return [
      baseColor,
      Color.lerp(baseColor, Colors.black, 0.4) ?? baseColor,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = card.cardColor;
    final gradientColors = _resolveGradients(baseColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CustomPaint(
          painter: _CardWavePainter(baseColor: baseColor),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
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
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Bank name & Card Type capsule
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.bankName.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                card.nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            card.cardType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Chip & Contactless wave icon
                    Row(
                      children: [
                        const EmvChipWidget(),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Card Number (formatted with clean spacing)
                    Text(
                      card.cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        letterSpacing: 2.4,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Footer: Cardholder, Expiry, and Network Logo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CARDHOLDER',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 9,
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.cardholderName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (card.formattedExpiry.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EXPIRES',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 9,
                                    letterSpacing: 0.9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.formattedExpiry,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        NetworkLogoDispatcher(
                          network: card.cardNetwork,
                          height: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItemData {
  final String title;
  final List<CardModel> cards;
  final List<Color> gradient;
  final IconData icon;

  const _CategoryItemData({
    required this.title,
    required this.cards,
    required this.gradient,
    required this.icon,
  });
}
