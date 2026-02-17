import 'dart:ui';
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: userAsync.when(
        data: (user) => Stack(
          children: [
            // ── Background Ambient Glow ────────────────────────
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCrux.withOpacity(0.2),
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                ),
              ),
            ),
             Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCyan.withOpacity(0.15),
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, kToolbarHeight + 40, 24, 40),
              child: Column(
                children: [
                  // ── Profile Avatar ───────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCrux.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.accentCrux, AppTheme.accentCyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Edit Badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                              ]
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ).animate().scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                  ),

                  const SizedBox(height: 20),
                  
                  Text(
                    user?.displayName ?? 'User',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    user?.email ?? '',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  // Subscription badge
                  GestureDetector(
                    onTap: () => context.push('/subscription'),
                     child: _GlassPill(
                      color: user?.isPremium == true ? AppTheme.accentLuxe.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                       borderColor: user?.isPremium == true ? AppTheme.accentLuxe.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user?.isPremium == true ? Icons.workspace_premium : Icons.star_outline_rounded,
                            size: 16,
                            color: user?.isPremium == true ? AppTheme.accentLuxe : AppTheme.textGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.isPremium == true ? 'Premium Member' : 'Free Plan • Upgrade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: user?.isPremium == true ? AppTheme.accentLuxe : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // ── Stats Row ────────────────────────────────────
                  Row(
                    children: [
                      _buildStatCard(context, 'Level', '${user?.level ?? 1}', AppTheme.accentCrux),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'XP', '${user?.totalXp ?? 0}', AppTheme.accentCyan),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Badges', '${user?.badges.length ?? 0}', AppTheme.accentRose),
                    ],
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 40),

                  // ── Menu Items ───────────────────────────────────
                  _SectionHeader(title: "Account"),
                  const SizedBox(height: 12),
                  
                  _GlassMenu(
                    children: [
                      _MenuItem(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Subscription',
                        subtitle: 'Manage your plan',
                        color: AppTheme.accentLuxe,
                        onTap: () => context.push('/subscription'),
                      ),
                        _Divider(),
                      _MenuItem(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: user?.preferredLanguage?.toUpperCase() ?? 'EN',
                        color: AppTheme.accentCyan,
                        onTap: () {},
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                   const SizedBox(height: 24),
                   _SectionHeader(title: "App Settings"),
                   const SizedBox(height: 12),

                   _GlassMenu(
                    children: [
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Push notification settings',
                        color: Colors.white,
                         onTap: () {},
                      ),
                      _Divider(),
                       _MenuItem(
                        icon: Icons.policy_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Data and account settings',
                        color: Colors.white,
                         onTap: () {},
                      ),
                      _Divider(),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        color: Colors.white,
                         onTap: () {},
                      ),
                    ],
                   ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 32),

                  // ── Logout Button ────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      await ref.read(currentUserProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign Out",
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentCrux),
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.6),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
           title.toUpperCase(),
           style: TextStyle(
             color: AppTheme.textMuted,
             fontSize: 12,
             fontWeight: FontWeight.bold,
             letterSpacing: 1.2,
           ),
        ),
      ),
    );
  }
}

class _GlassMenu extends StatelessWidget {
  final List<Widget> children;
  const _GlassMenu({required this.children});

  @override
  Widget build(BuildContext context) {
     return ClipRRect(
       borderRadius: BorderRadius.circular(24),
       child: BackdropFilter(
         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
         child: Container(
           decoration: BoxDecoration(
             color: AppTheme.cardDark,
             borderRadius: BorderRadius.circular(24),
             border: Border.all(color: Colors.white.withOpacity(0.05)),
           ),
           child: Column(children: children),
         ),
       ),
     );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppTheme.textGrey.withOpacity(0.5),
        size: 16,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 70);
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _GlassPill({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
