/// AI Muse — Profile Screen
/// User profile with settings, subscription status, and logout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';

/// User profile and settings screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Profile Avatar ───────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'User',
                style: context.textTheme.headlineMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 8),

              // Subscription badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: user?.isPremium == true
                      ? AppTheme.warning.withValues(alpha: 0.15)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user?.isPremium == true
                        ? AppTheme.warning.withValues(alpha: 0.3)
                        : AppTheme.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user?.isPremium == true
                          ? Icons.workspace_premium
                          : Icons.star_border,
                      size: 16,
                      color: user?.isPremium == true
                          ? AppTheme.warning
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.isPremium == true ? 'Premium' : 'Free Plan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user?.isPremium == true
                            ? AppTheme.warning
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // ── Stats Row ────────────────────────────────────
              Row(
                children: [
                  _buildStatCard(context, 'Level', '${user?.level ?? 1}',
                      AppTheme.accent),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'XP', '${user?.totalXp ?? 0}',
                      AppTheme.accentLuxe),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'Badges',
                      '${user?.badges.length ?? 0}', AppTheme.accentRose),
                ],
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // ── Menu Items ───────────────────────────────────
              _buildMenuItem(
                context,
                icon: Icons.workspace_premium,
                title: 'Subscription',
                subtitle: 'Manage your plan',
                color: AppTheme.warning,
                onTap: () => context.push('/subscription'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: user?.preferredLanguage?.toUpperCase() ?? 'EN',
                color: AppTheme.accentCrux,
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Push notification settings',
                color: AppTheme.accent,
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Data and account settings',
                color: AppTheme.success,
                onTap: () {},
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                color: AppTheme.textSecondary,
                onTap: () {},
              ),

              const SizedBox(height: 16),

              // ── Logout Button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(currentUserProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        tileColor: AppTheme.surfaceLight,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: context.textTheme.titleMedium),
        subtitle: Text(
          subtitle,
          style: context.textTheme.bodySmall,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
