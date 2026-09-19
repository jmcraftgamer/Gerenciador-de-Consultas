import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/form_helper.dart';
import '../utils/settings_service.dart';

class ConsultasScreen extends StatefulWidget {
  const ConsultasScreen({super.key});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  int _selectedDayIndex = 0;
  final _service = ConsultaService();
  Timer? _progressTimer;

  late List<_DayData> _diasSemana;

  String _getDataAtual() {
    final agora = DateTime.now();
    final meses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final diasSemana = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return '${agora.day} de ${meses[agora.month]}, ${diasSemana[agora.weekday]}';
  }

  void _calcularDiasSemana() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final abrev = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final meses = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    _diasSemana = List.generate(7, (i) {
      final d = startOfWeek.add(Duration(days: i));
      return _DayData(dia: abrev[i], data: '${d.day}/${meses[d.month]}');
    });
  }

  List<Consulta> _getConsultasHoje() {
    return _service.consultasPorData(DateTime.now());
  }

  List<Consulta> _getConsultasPorDiaSemana(int dayIndex) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetDay = startOfWeek.add(Duration(days: dayIndex));
    return _service.consultasPorData(targetDay);
  }

  int _getCountPorDiaSemana(int dayIndex) {
    return _getConsultasPorDiaSemana(dayIndex).length;
  }

  @override
  void initState() {
    super.initState();
    _calcularDiasSemana();
    _service.addListener(_onDataChanged);
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/Fundo2.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withValues(alpha: 0.75)),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),
                _buildPageHeading(),
                const SizedBox(height: AppSpacing.xl),
                _buildTodayCard(),
                const SizedBox(height: AppSpacing.md),
                _buildProgressBar(),
                const SizedBox(height: AppSpacing.lg),
                _buildConsultasHojePanel(),
                const SizedBox(height: AppSpacing.lg),
                _buildConsultasSemanaPanel(),
                const SizedBox(height: AppSpacing.lg),
                _buildQuoteBanner(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/R.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Widget _buildPageHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Consultas',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 48,
            color: AppColors.textPrimary,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Acompanhe suas consultas, gerencie seu dia e mantenha\nsua rotina em dia.',
          style: GoogleFonts.inter(
            fontSize: 17,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: AppColors.textPrimary,
            size: 39,
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoje',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _getDataAtual(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final consultasHoje = _getConsultasHoje();
    final total = consultasHoje.length;
    final agora = DateTime.now();
    int concluidas = 0;
    for (final c in consultasHoje) {
      final fim = DateTime(c.data.year, c.data.month, c.data.day, c.horarioFim.hour, c.horarioFim.minute);
      if (c.confirmada || agora.isAfter(fim)) {
        concluidas++;
      }
    }
    final pendentes = total - concluidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso do dia',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$concluidas/$total concluídas',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 10,
            child: total > 0
                ? Row(
                    children: [
                      if (concluidas > 0)
                        Expanded(
                          flex: concluidas,
                          child: Container(
                            decoration: const BoxDecoration(color: AppColors.confirmed),
                          ),
                        ),
                      if (pendentes > 0)
                        Expanded(
                          flex: pendentes,
                          child: Container(
                            decoration: const BoxDecoration(color: AppColors.pending),
                          ),
                        ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.confirmed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Concluídas ($concluidas)',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.base),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.pending,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Pendentes ($pendentes)',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultasHojePanel() {
    final consultas = _getConsultasHoje();
    return _buildPanel(
      icon: Icons.calendar_today,
      title: 'Consultas de hoje',
      trailing: '${consultas.length} consultas',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: consultas.isEmpty
            ? _buildEmptyState('Nenhuma consulta hoje')
            : Column(
                children: consultas.map((c) => _buildAppointmentCard(c)).toList(),
              ),
      ),
    );
  }

  Widget _buildAppointmentCard(Consulta c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(21),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 73,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary.withValues(alpha: 0.58),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(21),
                  bottomLeft: Radius.circular(21),
                ),
              ),
              child: Center(
                child: Text(
                  c.horarioFormatado.replaceAll(' – ', '\n—\n'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      c.paciente,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.dataFormatada,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          c.modalidade == 'Online' ? Icons.videocam : Icons.location_on,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.modalidade,
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
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.confirmada ? AppColors.statusBgGreen : AppColors.statusBgAmber,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                c.confirmada ? 'Confirmada' : 'Pendente',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: c.confirmada ? AppColors.confirmed : AppColors.pending,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (c.telefone.isNotEmpty)
              GestureDetector(
                onTap: () => abrirWhatsApp(c.telefone),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat, color: AppColors.white, size: 16),
                ),
              ),
            if (SettingsService().linkFormulario.isNotEmpty && c.telefone.isNotEmpty) ...[
              const SizedBox(width: 6),
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
            const SizedBox(width: 9),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultasSemanaPanel() {
    final consultasDoDia = _getConsultasPorDiaSemana(_selectedDayIndex);
    final d = _diasSemana[_selectedDayIndex];

    return Column(
      children: [
        _buildPanel(
          icon: Icons.calendar_today,
          title: 'Consultas da semana',
          trailing: '${_service.consultas.length} consultas',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_diasSemana.length, (index) {
                  final day = _diasSemana[index];
                  final isSelected = index == _selectedDayIndex;
                  final count = _getCountPorDiaSemana(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      width: 108,
                      margin: const EdgeInsets.only(right: 9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceSecondary.withValues(alpha: 0.57),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.14),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            day.dia,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            day.data,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.white.withValues(alpha: 0.82)
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            '$count',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 35,
                              color: isSelected ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            count == 1 ? 'consulta' : 'consultas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.white.withValues(alpha: 0.85)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (consultasDoDia.isNotEmpty)
          ...consultasDoDia.map((c) => _buildAppointmentCard(c))
        else
          _buildEmptyState('Nenhuma consulta em ${d.dia}'),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.quoteBanner,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Cuidar da mente também\né uma forma de se amar."',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: AppColors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '— BemEstar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required IconData icon,
    required String title,
    String? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 30),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DayData {
  final String dia;
  final String data;

  _DayData({required this.dia, required this.data});
}
