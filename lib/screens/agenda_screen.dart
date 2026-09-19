import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../theme/tokens.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';
import '../utils/pdf_service.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/form_helper.dart';
import '../utils/settings_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  final _service = ConsultaService();
  final _daysScrollController = ScrollController();

  static const _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  static const _dayAbbrev = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  static const _dayFull = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
      final targetOffset = (now.day - 1) * 62.0;
      final maxScroll = _daysScrollController.position.maxScrollExtent;
      _daysScrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/Fundo3.png', fit: BoxFit.cover),
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
                    _buildMonthSelector(),
                    const SizedBox(height: AppSpacing.base),
                    _buildDaysCarousel(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSelectedDayLabel(),
                    const SizedBox(height: AppSpacing.base),
                    _buildDayConsultations(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTodasConsultasPanel(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/R.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Agenda',
            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.textPrimary),
          ),
        ),
        GestureDetector(
          onTap: _mostrarOpcoesPdf,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.small),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Icons.chevron_right, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysCarousel() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _daysScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final day = index + 1;
          final date = DateTime(_currentMonth.year, _currentMonth.month, day);
          final isSelected = _dateKey(date) == _dateKey(_selectedDate);
          final isToday = _dateKey(date) == _dateKey(DateTime.now());
          final weekday = date.weekday;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.surfaceSecondary
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbrev[weekday],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayLabel() {
    final dayName = _dayFull[_selectedDate.weekday];
    final monthName = _monthNames[_selectedDate.month - 1];

    return Text(
      '$dayName, ${_selectedDate.day} de $monthName',
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDayConsultations() {
    final consultas = _service.consultasPorData(_selectedDate);

    if (consultas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nenhuma consulta neste dia',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: consultas.map((c) => _buildConsultaCard(c)).toList(),
    );
  }

  Widget _buildConsultaCard(Consulta consulta) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consulta.paciente,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      consulta.horarioFormatado,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (consulta.telefone.isNotEmpty)
            GestureDetector(
              onTap: () => abrirWhatsApp(consulta.telefone),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 20),
              ),
            ),
          if (SettingsService().linkFormulario.isNotEmpty && consulta.telefone.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => enviarFormulario(consulta.telefone, consulta.paciente),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodasConsultasPanel() {
    final todas = _service.consultasOrdenadas();
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
              child: const Icon(Icons.list_alt, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                'Todas as consultas',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${todas.length} total',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (todas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Icon(Icons.event_available, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nenhuma consulta marcada',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          Column(
            children: todas.map((c) => _buildTodasConsultaItem(c)).toList(),
          ),
      ],
    );
  }

  Widget _buildTodasConsultaItem(Consulta c) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              c.modalidade == 'Online' ? Icons.videocam : Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.paciente,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.dataFormatada} • ${c.horarioFormatado}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
        ],
      ),
    );
  }

  void _mostrarOpcoesPdf() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gerar PDF',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha o período do relatório',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _buildPdfOption(
                icon: Icons.today,
                title: 'Consultas de Hoje',
                description: 'Relatório com as consultas do dia atual',
                periodo: 'dia',
              ),
              const SizedBox(height: 8),
              _buildPdfOption(
                icon: Icons.view_week_outlined,
                title: 'Consultas da Semana',
                description: 'Relatório com as consultas desta semana',
                periodo: 'semana',
              ),
              const SizedBox(height: 8),
              _buildPdfOption(
                icon: Icons.calendar_month_outlined,
                title: 'Consultas do Mês',
                description: 'Relatório com as consultas deste mês',
                periodo: 'mes',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfOption({
    required IconData icon,
    required String title,
    required String description,
    required String periodo,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _gerarEMostrarPreview(periodo);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _gerarEMostrarPreview(String periodo) async {
    final pdf = await PdfService().gerarPdf(periodo);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PdfPreviewScreen(pdf: pdf, periodo: periodo),
      ),
    );
  }
}

class _PdfPreviewScreen extends StatelessWidget {
  final pw.Document pdf;
  final String periodo;

  const _PdfPreviewScreen({required this.pdf, required this.periodo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview do PDF',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: () async {
              await PdfService().baixarPdf(periodo, existingPdf: pdf);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF baixado com sucesso!', style: GoogleFonts.inter()), backgroundColor: AppColors.primary),
                );
              }
            },
            tooltip: 'Baixar',
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primary),
            onPressed: () => PdfService().imprimirPdf(periodo, existingPdf: pdf),
            tooltip: 'Imprimir',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () => PdfService().compartilharPdf(periodo, existingPdf: pdf),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => pdf.save(),
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(child: _buildActionBtn(icon: Icons.download, label: 'Baixar', onTap: () async { await PdfService().baixarPdf(periodo, existingPdf: pdf); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF salvo!', style: GoogleFonts.inter()), backgroundColor: AppColors.primary)); } })),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn(icon: Icons.print, label: 'Imprimir', onTap: () => PdfService().imprimirPdf(periodo, existingPdf: pdf))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn(icon: Icons.share, label: 'Compartilhar', onTap: () => PdfService().compartilharPdf(periodo, existingPdf: pdf))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.medium)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}
