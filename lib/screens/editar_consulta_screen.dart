import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';

class EditarConsultaScreen extends StatefulWidget {
  final Consulta consulta;

  const EditarConsultaScreen({
    super.key,
    required this.consulta,
  });

  @override
  State<EditarConsultaScreen> createState() => _EditarConsultaScreenState();
}

class _EditarConsultaScreenState extends State<EditarConsultaScreen> {
  late TextEditingController _pacienteController;
  late TextEditingController _telefoneController;
  late String _modalidade;
  late bool _confirmada;

  @override
  void initState() {
    super.initState();
    _pacienteController = TextEditingController(text: widget.consulta.paciente);
    _telefoneController = TextEditingController(text: widget.consulta.telefone);
    _modalidade = widget.consulta.modalidade;
    _confirmada = widget.consulta.confirmada;
  }

  @override
  void dispose() {
    _pacienteController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _salvar() {
    final atualizada = Consulta(
      id: widget.consulta.id,
      paciente: _pacienteController.text.trim(),
      data: widget.consulta.data,
      horarioInicio: widget.consulta.horarioInicio,
      horarioFim: widget.consulta.horarioFim,
      modalidade: _modalidade,
      telefone: _telefoneController.text.trim(),
      queixas: widget.consulta.queixas,
      confirmada: _confirmada,
    );

    ConsultaService().atualizar(widget.consulta.id, atualizada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Consulta atualizada!',
          style: GoogleFonts.inter(color: AppColors.white),
        ),
        backgroundColor: AppColors.confirmed,
      ),
    );

    Navigator.pop(context);
  }

  void _remover() {
    final consultas = ConsultaService();
    final removida = widget.consulta;
    consultas.remover(removida.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Consulta removida',
          style: GoogleFonts.inter(color: AppColors.white),
        ),
        backgroundColor: AppColors.danger,
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: AppColors.white,
          onPressed: () {
            consultas.adicionar(removida);
          },
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/R.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          'Editar Consulta',
          style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nome do Paciente', Icons.person_outline),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: TextField(
                controller: _pacienteController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildLabel('Telefone / WhatsApp', Icons.phone_outlined),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: TextField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '(00) 00000-0000',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildLabel('Data', Icons.calendar_today),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(
                widget.consulta.dataFormatada,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildLabel('Horário', Icons.access_time),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(
                widget.consulta.horarioFormatado,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildLabel('Modalidade', null),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _buildModalButton('Presencial', Icons.location_on, _modalidade == 'Presencial')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildModalButton('Online', Icons.videocam, _modalidade == 'Online')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildLabel('Status', null),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _confirmada = true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _confirmada ? AppColors.confirmed : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: _confirmada ? AppColors.white : AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Confirmada', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _confirmada ? AppColors.white : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _confirmada = false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: !_confirmada ? AppColors.pending : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 18, color: !_confirmada ? AppColors.white : AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Pendente', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: !_confirmada ? AppColors.white : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.consulta.queixas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildLabel('Queixas', null),
              const SizedBox(height: AppSpacing.sm),
              ...widget.consulta.queixas.map((q) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.pending,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          q,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _salvar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, color: AppColors.white, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Salvar Alterações', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData? icon) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildModalButton(String label, IconData icon, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _modalidade = label),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.white : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: active ? AppColors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Remover consulta', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Text('Tem certeza que deseja remover esta consulta?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remover();
            },
            child: Text('Remover', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
