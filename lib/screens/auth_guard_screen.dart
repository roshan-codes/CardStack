import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';

class AuthGuardScreen extends StatefulWidget {
  final AuthService? authService;
  final Widget? destination;
  final Widget? child;
  final bool autoPrompt;
  final bool initiallyAuthenticated;

  const AuthGuardScreen({
    super.key,
    this.authService,
    this.destination,
    this.child,
    this.autoPrompt = true,
    this.initiallyAuthenticated = false,
  });

  @override
  State<AuthGuardScreen> createState() => _AuthGuardScreenState();
}

class _AuthGuardScreenState extends State<AuthGuardScreen>
    with WidgetsBindingObserver {
  late final AuthService _authService;
  late bool _isAuthenticated;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _isAuthenticated = widget.initiallyAuthenticated;
    WidgetsBinding.instance.addObserver(this);

    if (!_isAuthenticated && widget.autoPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically re-lock wallet when app goes into background or inactive for privacy & security
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _errorMessage = null;
        });
      }
    } else if (state == AppLifecycleState.resumed &&
        !_isAuthenticated &&
        widget.autoPrompt) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final success = await _authService.authenticate(
      reason: 'Use Face ID or Phone Passcode to access your CardStack',
    );

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = success;
        if (!success) {
          _errorMessage =
              'Authentication canceled or failed. Tap below to retry.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child ?? widget.destination ?? const CardWalletScreen();
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Badge / Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'CardStack Locked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock using Face ID or your phone lock (passcode/PIN) to access your cards safely.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(
                      _isAuthenticating
                          ? 'Authenticating...'
                          : 'Unlock CardStack',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
