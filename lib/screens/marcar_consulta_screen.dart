import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../utils/audio_manager.dart';
import '../utils/notification_service.dart';
import '../widgets/effects.dart';
import '../widgets/animations.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';

class MarcarConsultaScreen extends StatefulWidget {
  const MarcarConsultaScreen({super.key});

  @override
  State<MarcarConsultaScreen> createState() => _MarcarConsultaScreenState();
}

class _MarcarConsultaScreenState extends State<MarcarConsultaScreen> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  String modalidade = 'Presencial';
  DateTime? _dataSelecionada;
  TimeOfDay? _horarioInicio;
  TimeOfDay? _horarioFim;
  final List<String> _queixas = [];
  final _queixaController = TextEditingController();
  final _audio = AudioManager();
  final _service = ConsultaService();

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _queixaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    HapticFeedback.lightImpact();
    _audio.playTap();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHorario({required bool isInicio}) async {
    HapticFeedback.lightImpact();
    _audio.playTap();

    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione a data primeiro', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final ocupados = _service.horariosOcupados(_dataSelecionada!);
    final horarios = List.generate(12, (i) => i + 7);

    final selecionado = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                isInicio ? 'Horário de início' : 'Horário de fim',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Horário de atendimento: 7h às 18h',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: horarios.length,
                  itemBuilder: (ctx, index) {
                    final h = horarios[index];
                    final ocupado = ocupados.contains(h);
                    final horaStr = '${h.toString().padLeft(2, '0')}:00';

                    return GestureDetector(
                      onTap: ocupado
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _audio.playSelect();
                              Navigator.pop(ctx, h);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: ocupado
                              ? AppColors.textSecondary.withValues(alpha: 0.1)
                              : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(
                            color: ocupado
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppColors.textSecondary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              horaStr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ocupado
                                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (ocupado)
                              Text(
                                'Ocupado',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.red.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        );
      },
    );

    if (selecionado != null) {
      setState(() {
        if (isInicio) {
          _horarioInicio = TimeOfDay(hour: selecionado, minute: 0);
          if (selecionado == 18) {
            _horarioFim = null;
          } else if (_horarioFim == null || _horarioFim!.hour <= selecionado) {
            final nextHour = (selecionado + 1 <= 18) ? selecionado + 1 : 18;
            _horarioFim = TimeOfDay(hour: nextHour, minute: 0);
          }
        } else {
          if (_horarioInicio != null && selecionado <= _horarioInicio!.hour) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('O horário de fim deve ser posterior ao início', style: GoogleFonts.inter()),
                backgroundColor: Colors.orange.shade700,
              ),
            );
            return;
          }
          _horarioFim = TimeOfDay(hour: selecionado, minute: 0);
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }

  void _adicionarQueixa() {
    final texto = _queixaController.text.trim();
    if (texto.isNotEmpty) {
      HapticFeedback.lightImpact();
      _audio.playSelect();
      setState(() {
        _queixas.add(texto);
        _queixaController.clear();
      });
    }
  }

  void _removerQueixa(String queixa) {
    HapticFeedback.lightImpact();
    _audio.playDelete();
    setState(() => _queixas.remove(queixa));
  }

  void _salvarConsulta() {
    if (_nomeController.text.isEmpty || _dataSelecionada == null || _horarioInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha nome, data e horário', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_horarioFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione o horário de fim', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final inicioMinutos = _horarioInicio!.hour * 60 + _horarioInicio!.minute;
    final fimMinutos = _horarioFim!.hour * 60 + _horarioFim!.minute;
    if (fimMinutos <= inicioMinutos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O horário de fim deve ser depois do início', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final ocupados = _service.horariosOcupados(_dataSelecionada!);
    for (var h = _horarioInicio!.hour; h < _horarioFim!.hour; h++) {
      if (ocupados.contains(h)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esse horário já está ocupado nessa data', style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    HapticFeedback.mediumImpact();
    _audio.playSuccess();

    final novaConsulta = Consulta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paciente: _nomeController.text,
      telefone: _telefoneController.text,
      data: _dataSelecionada!,
      horarioInicio: _horarioInicio!,
      horarioFim: _horarioFim ?? TimeOfDay(hour: _horarioInicio!.hour + 1, minute: _horarioInicio!.minute),
      modalidade: modalidade,
      queixas: _queixas,
    );

    _service.adicionar(novaConsulta);
    NotificationService().notificarConsultaCriada(novaConsulta);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Consulta marcada com sucesso!', style: GoogleFonts.inter()),
        backgroundColor: AppColors.primary,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Fundo2.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.75)),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _audio.playBack();
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.base),
                        FloatingWidget(
                          offset: 2,
                          duration: const Duration(milliseconds: 3500),
                          child: Image.asset(
                            'assets/R.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Marcar Consulta',
                          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            FadeInWidget(delayMs: 0, child: _buildTextField('Nome do paciente', _nomeController, Icons.person_outline)),
            const SizedBox(height: AppSpacing.base),
            FadeInWidget(delayMs: 100, child: _buildTextField('Telefone (opcional)', _telefoneController, Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            )),
            const SizedBox(height: AppSpacing.base),
            FadeInWidget(delayMs: 200, child: _buildDatePicker()),
            const SizedBox(height: AppSpacing.base),
            FadeInWidget(delayMs: 300, child: _buildTimePickers()),
            const SizedBox(height: AppSpacing.base),
            FadeInWidget(delayMs: 400, child: _buildModalitySelector()),
            const SizedBox(height: AppSpacing.base),
            FadeInWidget(delayMs: 500, child: _buildQueixasSection()),
            const SizedBox(height: AppSpacing.xl),
            FadeInWidget(delayMs: 600, child: _buildSaveButton()),
            const SizedBox(height: 100),
                ],
              ),
            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, List<TextInputFormatter>? formatters}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
        ),
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selecionarData,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.base),
            Text(
              _dataSelecionada != null
                  ? '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}'
                  : 'Selecionar data',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _dataSelecionada != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selecionarHorario(isInicio: true),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _horarioInicio != null ? _formatTime(_horarioInicio!) : 'Início',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _horarioInicio != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: GestureDetector(
            onTap: () => _selecionarHorario(isInicio: false),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _horarioFim != null ? _formatTime(_horarioFim!) : 'Fim',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _horarioFim != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalitySelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _audio.playSelect();
              setState(() => modalidade = 'Presencial');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: modalidade == 'Presencial' ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: modalidade == 'Presencial' ? AppColors.primary : AppColors.surface,
                ),
                boxShadow: modalidade == 'Presencial'
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: modalidade == 'Presencial' ? AppColors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Presencial',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: modalidade == 'Presencial' ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _audio.playSelect();
              setState(() => modalidade = 'Online');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: modalidade == 'Online' ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: modalidade == 'Online' ? AppColors.primary : AppColors.surface,
                ),
                boxShadow: modalidade == 'Online'
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 18,
                    color: modalidade == 'Online' ? AppColors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Online',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: modalidade == 'Online' ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueixasSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queixas do paciente',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queixaController,
                  decoration: InputDecoration(
                    hintText: 'Adicionar queixa',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  onSubmitted: (_) => _adicionarQueixa(),
                ),
              ),
              GestureDetector(
                onTap: _adicionarQueixa,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: AppColors.white),
                ),
              ),
            ],
          ),
          if (_queixas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _queixas.map((q) {
                return Chip(
                  label: Text(q, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removerQueixa(q),
                  backgroundColor: AppColors.surfaceSecondary,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GlowWidget(
      glowColor: AppColors.primary,
      spreadRadius: 8,
      child: GestureDetector(
        onTap: _salvarConsulta,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Marcar Consulta',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
