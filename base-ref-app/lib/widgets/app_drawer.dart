/*
Copyright (c) 2026 Adobe. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../features/session/session_provider.dart';

/// App-wide navigation drawer. Lists features, each routing to its own page.
/// New features are added as entries here.
class AppDrawer extends ConsumerWidget {
  /// Route of the page currently shown, used to highlight the active item.
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: _DrawerBrand(),
            ),
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Home',
              route: '/',
              currentRoute: currentRoute,
            ),
            const Spacer(),
            if (session != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF6B6B6B)),
                title: Text(
                  session.userId,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Signed in',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(sessionProvider.notifier).signOut();
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Partner reference app',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBrand extends StatelessWidget {
  const _DrawerBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: adobeRed,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Partner Ref App',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: active ? adobeRed : const Color(0xFF6B6B6B)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? adobeRed : const Color(0xFF1F1F1F),
        ),
      ),
      selected: active,
      selectedTileColor: adobeRed.withValues(alpha: 0.06),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer
        if (!active) context.go(route);
      },
    );
  }
}
