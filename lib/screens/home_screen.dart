import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../utils/phrase_manager.dart';
import '../utils/audio_manager.dart';
import '../navigation/main_navigation.dart';
import '../widgets/animated_card.dart';
import '../widgets/effects.dart';
import '../models/consulta_service.dart';
import '../models/consulta.dart';
import '../utils/form_helper.dart';
import '../utils/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _dailyPhrase = '';
  bool _loadingPhrase = true;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _glowController;
  final _audio = AudioManager();
  final _service = ConsultaService();

  @override
  void initState() {
    super.initState();
    _loadPhrase();
    _service.addListener(_onDataChanged);

    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerController.forward();

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    _headerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPhrase() async {
    final phrase = await PhraseManager.getCurrentPhrase();
    if (mounted) {
      setState(() {
        _dailyPhrase = phrase;
        _loadingPhrase = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/Fundo1.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withValues(alpha: 0.75)),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),
                AnimatedCard(delay: 100, child: _buildWelcomeCard()),
                const SizedBox(height: AppSpacing.xl),
                _buildQuickAccess(),
                const SizedBox(height: AppSpacing.xl),
                AnimatedCard(delay: 600, child: _buildTodayConsultations()),
                const SizedBox(height: AppSpacing.xl),
                AnimatedCard(delay: 800, child: _buildQuoteCard()),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Row(
          children: [
            FloatingWidget(
              offset: 3,
              duration: const Duration(milliseconds: 3000),
              child: Image.asset(
                'assets/R.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BemEstar',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Psicanalista ao seu lado',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final nome = SettingsService().nome;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seja Bem-Vinda,',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nome,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"Cuidar da mente é o ato mais corajoso de autocuidado."',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    final items = [
      _QuickAccessData(Icons.calendar_today_outlined, 'Gerenciador de Consultas', 'Veja, edite e organize suas consultas', 0),
      _QuickAccessData(Icons.person_add_outlined, 'Marcar Consulta', 'Agende um novo atendimento', 2),
      _QuickAccessData(Icons.calendar_view_month_outlined, 'Calendário', 'Veja os dias e horários', 3),
      _QuickAccessData(Icons.list_alt_outlined, 'Ver Consultas', 'Confira todas as suas consultas', 1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acesso rápido',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.asMap().entries.map((entry) {
          return AnimatedCard(
            delay: 200 + (entry.key * 100),
            onTap: () {
              _audio.playNavigate();
              final nav = context.findAncestorStateOfType<MainNavigationState>();
              nav?.switchTab(entry.value.navIndex);
            },
            child: _buildQuickAccessCardContent(entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildQuickAccessCardContent(_QuickAccessData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3 * _glowController.value),
                      blurRadius: 8 * _glowController.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(item.icon, color: AppColors.white, size: 22),
              );
            },
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.5 + _glowController.value * 0.5)),
        ],
      ),
    );
  }

  Widget _buildTodayConsultations() {
    final consultasHoje = ConsultaService().consultasPorData(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: const Icon(Icons.today_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                'Consultas de Hoje',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _audio.playNavigate();
                final nav = context.findAncestorStateOfType<MainNavigationState>();
                nav?.switchTab(3);
              },
              child: Row(
                children: [
                  Text(
                    'Ver mais',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (consultasHoje.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_outlined, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nenhuma consulta hoje',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: consultasHoje.map((c) => _buildConsultaRealItem(c)).toList(),
          ),
      ],
    );
  }

  Widget _buildConsultaRealItem(Consulta c) {
    final settings = SettingsService();
    final podeEnviarForm = settings.linkFormulario.isNotEmpty && c.telefone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.paciente,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      c.horarioFormatado,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: c.modalidade == 'Online' ? AppColors.statusBgGreen : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              c.modalidade,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (podeEnviarForm) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => enviarFormulario(c.telefone, c.paciente),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, color: Colors.white, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return WaveWidget(
      duration: const Duration(milliseconds: 4000),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: _loadingPhrase
                  ? const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$_dailyPhrase"',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 17,
                            color: AppColors.white,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '— Frase do dia',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
            ),
            PulseWidget(
              minScale: 0.9,
              maxScale: 1.1,
              duration: const Duration(milliseconds: 3000),
              child: Icon(
                Icons.local_florist_outlined,
                size: 40,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessData {
  final IconData icon;
  final String title;
  final String description;
  final int navIndex;
  _QuickAccessData(this.icon, this.title, this.description, this.navIndex);
}
