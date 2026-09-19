import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../utils/audio_manager.dart';
import '../widgets/bottom_navigation.dart';
import '../screens/home_screen.dart';
import '../screens/consultas_screen.dart';
import '../screens/marcar_consulta_screen.dart';
import '../screens/agenda_screen.dart';
import '../screens/configuracoes_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final PageController _pageController;
  final _audio = AudioManager();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _screens = [
      const HomeScreen(),
      const ConsultasScreen(),
      const SizedBox.shrink(),
      const AgendaScreen(),
      const ConfiguracoesScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _navToPage(int navIndex) {
    if (navIndex == 0) return 0;
    if (navIndex == 1) return 1;
    if (navIndex == 3) return 2;
    if (navIndex == 4) return 3;
    return 0;
  }

  void switchTab(int index) {
    if (index == 2) {
      _audio.playNavigate();
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => const MarcarConsultaScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween(begin: 0.0, end: 1.0);
            final scaleTween = Tween(begin: 0.95, end: 1.0);
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: ScaleTransition(
                  scale: animation.drive(scaleTween),
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    } else {
      _audio.playSelect();
      _pageController.jumpToPage(
        _navToPage(index),
      );
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (pageIndex) {
            _audio.playTap();
            final navIndex = [0, 1, 3, 4][pageIndex];
            setState(() {
              _currentIndex = navIndex;
            });
          },
          children: [
            _screens[0],
            _screens[1],
            _screens[3],
            _screens[4],
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: switchTab,
      ),
    );
  }
}
