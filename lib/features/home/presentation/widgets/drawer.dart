import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mindful_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:mindful_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mindful_app/theme/app_colors.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key, required this.drawerKey});
  final GlobalKey drawerKey;
  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/auth');
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.session.user : null;
        final email = user?.email ?? 'Guest User';
        final name = user?.userMetadata?['full_name'] ?? 'Mindful User';
        final avatarUrl = user?.userMetadata?['avatar_url'];

        return Drawer(
          key: widget.drawerKey,
          backgroundColor: AppColors.surface,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (user == null)
                      ListTile(
                        leading: const Icon(Icons.login, color: Colors.white),
                        title: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () => context.go('/auth'),
                      ),
                    _DrawerItem(
                      icon: FontAwesomeIcons.crown,
                      title: 'Go Premium',
                      subtitle: 'Unlock all features',
                      color: Colors.amber,
                      onTap: () {
                        // Navigate to premium
                      },
                    ),
                    const Divider(color: Colors.white24),
                    _DrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {},
                    ),
                    _DrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _DrawerItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _DrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: Colors.redAccent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);

                                context.read<AuthBloc>().add(AuthSignOut());
                                context.go("/");
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: (color ?? Colors.white).withOpacity(0.7),
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
