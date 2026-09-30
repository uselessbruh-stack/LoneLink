/// LONE LINK — Identity Setup Screen
///
/// First-launch screen where the user creates their device identity.
/// Generates cryptographic keypair and lets user set a display name.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:lone_link/presentation/router.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/core/logging/app_logger.dart';
import 'package:lone_link/storage/database/database.dart';

class IdentitySetupScreen extends ConsumerStatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  ConsumerState<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends ConsumerState<IdentitySetupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _currentStep = 1;
    });

    try {
      // Step 1: Generate identity ID
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _currentStep = 2);

      // Step 2: Generate cryptographic keys
      // TODO(Phase 8): Replace with real Ed25519 + X25519 key generation
      // For Phase 1, we use placeholder bytes to validate the architecture.
      final identityId = const Uuid().v4();
      final publicKey = Uint8List(32); // Placeholder — Phase 8 will generate real Ed25519 keys
      final keyExchangePublicKey = Uint8List(32); // Placeholder — Phase 8 will generate real X25519 keys

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _currentStep = 3);

      // Step 3: Save to database using raw insert via the database directly
      final db = ref.read(databaseProvider);
      await db.into(db.localIdentities).insert(
        LocalIdentitiesCompanion.insert(
          id: identityId,
          displayName: _nameController.text.trim(),
          publicKey: publicKey,
          keyExchangePublicKey: keyExchangePublicKey,
          createdAt: DateTime.now(),
        ),
      );

      log.info(LogCategory.lifecycle, 'Identity created', 'ID: $identityId');

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      ref.read(isSetupCompleteProvider.notifier).state = true;
      context.go(AppRoutes.conversations);
    } catch (e, st) {
      log.error(LogCategory.lifecycle, 'Failed to create identity', e, st);
      if (mounted) {
        setState(() {
          _isCreating = false;
          _currentStep = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create identity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoneLinkColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _isCreating ? _buildCreatingView() : _buildSetupForm(),
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LoneLinkColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1,
            size: 40,
            color: LoneLinkColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Create Your\nIdentity',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),

        Text(
          'Your identity is generated on this device. '
          'A cryptographic keypair will be created to secure your messages.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 36),

        // Display name form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: LoneLinkColors.darkTextPrimary,
            ),
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.face, color: LoneLinkColors.primary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a display name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              if (value.trim().length > 50) {
                return 'Name must be 50 characters or less';
              }
              return null;
            },
            onFieldSubmitted: (_) => _createIdentity(),
          ),
        ),
        const SizedBox(height: 12),

        // Privacy note
        Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 14, color: LoneLinkColors.darkTextTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your display name is separate from your cryptographic identity. '
                'It can be changed later.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),

        const Spacer(flex: 3),

        // Create button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createIdentity,
            child: const Text('Create Identity'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCreatingView() {
    final steps = [
      'Initializing...',
      'Generating identity',
      'Creating cryptographic keys',
      'Saving to secure storage',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated lock icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LoneLinkColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.enhanced_encryption,
                    size: 48,
                    color: LoneLinkColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        Text(
          'Setting up your identity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 32),

        // Progress steps
        ...List.generate(steps.length, (index) {
          final isDone = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                if (isDone)
                  const Icon(Icons.check_circle, size: 20, color: LoneLinkColors.success)
                else if (isCurrent)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation(LoneLinkColors.primary),
                    ),
                  )
                else
                  Icon(Icons.circle_outlined, size: 20,
                      color: LoneLinkColors.darkTextTertiary.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDone || isCurrent
                        ? LoneLinkColors.darkTextPrimary
                        : LoneLinkColors.darkTextTertiary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
