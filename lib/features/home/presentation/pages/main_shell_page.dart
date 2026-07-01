import 'package:flutter/material.dart';
import '../../../applications/presentation/pages/applications_tab_page.dart';
import '../../../opportunities/presentation/pages/explore_tab_page.dart';
import '../../../profile/presentation/pages/profile_tab_page.dart';
import 'home_tab_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  void _goToExplore() => setState(() => _currentIndex = 1);

  late final List<Widget> _pages = [
    HomeTabPage(onExploreTap: _goToExplore),
    const ExploreTabPage(),
    const ApplicationsTabPage(),
    const ProfileTabPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
