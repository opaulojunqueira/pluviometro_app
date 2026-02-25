import 'package:flutter/material.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/features/profile/profile_screen.dart';

/// AppBar compartilhado entre todas as tabs do HomeScreen.
/// Exibe o logo do app e o avatar com as iniciais do usuário.
class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static String getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = PreferencesService.instance.userName;
    final initials = getInitials(name);

    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.water_drop, color: Colors.white),
          SizedBox(width: 8),
          Text('Pluviômetro Digital', style: TextStyle(color: Colors.white)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
                  .then((_) {
                // Trigger rebuild of the parent StatefulWidget if needed
                // This is handled by the tab refresh mechanism in HomeScreen
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
