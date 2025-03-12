import 'package:flutter/material.dart';

/// A reusable top navigation bar (AppBar) for web-friendly layout.
/// We remove the "History" button by commenting it out.
class UniversalNavigation extends StatelessWidget
    implements PreferredSizeWidget {
  final int currentIndex;
  final String pageTitle;

  const UniversalNavigation({
    Key? key,
    required this.currentIndex,
    required this.pageTitle,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    // Avoid re-navigating if already on the same screen.
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/recording',
          (route) => false,
        );
        break;
      // case 1: // History page is commented out
      //   Navigator.pushNamedAndRemoveUntil(context, '/history', (route) => false);
      //   break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/upload', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/settings',
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Match your style:
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(pageTitle, style: const TextStyle(color: Colors.black87)),
      iconTheme: const IconThemeData(color: Colors.deepPurple),

      // Right-aligned navigation buttons:
      actions: [
        TextButton(
          onPressed: () => _onItemTapped(context, 0),
          child: Text(
            'Recording',
            style: TextStyle(
              color: currentIndex == 0 ? Colors.deepPurple : Colors.grey[700],
            ),
          ),
        ),
        // TextButton(
        //   onPressed: () => _onItemTapped(context, 1),
        //   child: Text(
        //     'History',
        //     style: TextStyle(
        //       color: currentIndex == 1 ? Colors.deepPurple : Colors.grey[700],
        //     ),
        //   ),
        // ),
        TextButton(
          onPressed: () => _onItemTapped(context, 1),
          child: Text(
            'Upload',
            style: TextStyle(
              color: currentIndex == 1 ? Colors.deepPurple : Colors.grey[700],
            ),
          ),
        ),
        TextButton(
          onPressed: () => _onItemTapped(context, 2),
          child: Text(
            'Settings',
            style: TextStyle(
              color: currentIndex == 2 ? Colors.deepPurple : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // Because we're returning an AppBar, implement preferredSize:
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
