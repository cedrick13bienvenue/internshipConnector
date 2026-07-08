import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../applications/presentation/pages/applications_tab_page.dart';
import '../../../applications/presentation/pages/startup_applicants_tab_page.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
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
  bool? _isStartup;
  List<Widget>? _pages;

  void _goToExplore() => setState(() => _currentIndex = 1);

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    _isStartup = auth is AuthAuthenticated && auth.user.role == UserRole.startup;

    _pages = _isStartup
        ? [
            HomeTabPage(onExploreTap: _goToExplore),
            const StartupApplicantsTabPage(),
            const ProfileTabPage(),
          ]
        : [
            HomeTabPage(onExploreTap: _goToExplore),
            const ExploreTabPage(),
            const ApplicationsTabPage(),
            const ProfileTabPage(),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _isStartup
            ? const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people_alt_rounded), label: 'Applicants'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded), label: 'Profile'),
              ]
            : const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.explore_rounded), label: 'Explore'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_rounded), label: 'Applications'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
      ),
    );
  }
}
