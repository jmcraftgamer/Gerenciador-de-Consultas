import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../utils/audio_manager.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with TickerProviderStateMixin {
  final _audio = AudioManager();
  late AnimationController _centerController;
  late Animation<double> _centerScale;
  late Animation<double> _centerGlow;

  @override
  void initState() {
    super.initState();
    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _centerScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _centerController, curve: Curves.easeInOut),
    );
    _centerGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _centerController, curve: Curves.easeInOut),
    );
    _centerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _centerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildItem(0, Icons.home_outlined, Icons.home, 'Início'),
              _buildItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Consultas'),
              _buildCenterButton(),
              _buildItem(3, Icons.calendar_month_outlined, Icons.calendar_month, 'Agenda'),
              _buildItem(4, Icons.settings_outlined, Icons.settings, 'Configurações'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isActive = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        _audio.playSelect();
        widget.onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? filledIcon : outlineIcon,
                key: ValueKey('$index-$isActive'),
                size: isActive ? 24 : 22,
                color: isActive ? AppColors.darkCard : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.darkCard : AppColors.textSecondary,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(top: 4),
              width: isActive ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [BoxShadow(color: AppColors.darkCard.withValues(alpha: 0.3), blurRadius: 6)]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () {
        _audio.playTap();
        widget.onTap(2);
      },
      child: AnimatedBuilder(
        animation: _centerController,
        builder: (context, child) {
          return Transform.scale(
            scale: _centerScale.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkCard.withValues(alpha: _centerGlow.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 28, color: AppColors.white),
            ),
          );
        },
      ),
    );
  }
}
