import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tokens.dart';
import '../utils/audio_manager.dart';
import '../utils/settings_service.dart';
import '../utils/backup_service.dart';
import '../models/consulta_service.dart';
import '../widgets/effects.dart';
import '../widgets/animations.dart';
import '../widgets/animated_card.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _audio = AudioManager();
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _editarPerfil() {
    final nomeController = TextEditingController(text: _settings.nome);
    final emailController = TextEditingController(text: _settings.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar Perfil',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _settings.atualizarPerfil(
                          nome: nomeController.text.trim(),
                          email: emailController.text.trim(),
                        );
                        _audio.playSuccess();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Salvar', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) {
      nomeController.dispose();
      emailController.dispose();
    });
  }

  void _editarLembrete() {
    final opcoes = [0, 15, 30, 60];
    final labels = ['Desativado', '15 minutos antes', '30 minutos antes', '1 hora antes'];

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
              Text(
                'Lembrete antes da consulta',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ...List.generate(opcoes.length, (i) {
                final isSelected = _settings.lembreteMinutos == opcoes[i];
                return ListTile(
                  onTap: () {
                    _settings.setLembreteMinutos(opcoes[i]);
                    _audio.playSelect();
                    Navigator.pop(ctx);
                  },
                  title: Text(labels[i], style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  )),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _editarTamanhoFonte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tamanho da fonte',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exemplo de texto',
                    style: GoogleFonts.inter(
                      fontSize: 14 * _settings.tamanhoFonte,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _settings.tamanhoFonte,
                    min: 0.8,
                    max: 1.3,
                    divisions: 5,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      setModalState(() {});
                      _settings.setTamanhoFonte(v);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      Text('A', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      Text('A', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _settings.tamanhoFonteLabel,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _limparConsultas() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Limpar consultas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          content: Text(
            'Tem certeza que deseja apagar todas as consultas? Esta ação não pode ser desfeita.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                ConsultaService().limparTodas();
                _audio.playDelete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Todas as consultas foram removidas', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Text('Limpar', style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _editarNumeroPsicologa() {
    final controller = TextEditingController(text: _settings.numeroPsicologa);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Seu número WhatsApp', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'DDD + número (ex: 11999998888)',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _settings.setNumeroPsicologa(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Número salvo!', style: GoogleFonts.inter()), backgroundColor: AppColors.confirmed),
              );
            },
            child: Text('Salvar', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _editarMensagemFormulario() {
    final controller = TextEditingController(text: _settings.mensagemFormulario);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mensagem do formulário', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Use {nome} para o nome do paciente e {link} para o link do formulário',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Variáveis: {nome} = nome do paciente, {link} = link do formulário',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _settings.setMensagemFormulario(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mensagem salva!', style: GoogleFonts.inter()), backgroundColor: AppColors.confirmed),
              );
            },
            child: Text('Salvar', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _editarLinkFormulario() {
    final controller = TextEditingController(text: _settings.linkFormulario);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Link do formulário', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://forms.google.com/seu-formulario',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _settings.setLinkFormulario(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link salvo!', style: GoogleFonts.inter()), backgroundColor: AppColors.confirmed),
              );
            },
            child: Text('Salvar', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _mostrarSobre() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/R.png', width: 60, height: 60),
              const SizedBox(height: 16),
              Text('BemEstar', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Psicanalista ao seu lado', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Text('Versão 1.0.0', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Text(
                'App de gerenciamento de consultas para profissionais de psicanálise.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Fechar', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
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
                    FadeInWidget(
                      delayMs: 0,
                      child: Row(
                        children: [
                          FloatingWidget(
                            offset: 2,
                            duration: const Duration(milliseconds: 3500),
                            child: Image.asset(
                              'assets/R.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Configurações', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInWidget(delayMs: 100, child: _buildProfileCard()),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInWidget(delayMs: 200, child: _buildGroup('Conta', [
                      _SettingData(Icons.person_outline, 'Perfil', 'Gerencie seus dados pessoais', onTap: _editarPerfil),
                      _SettingData(Icons.notifications_outlined, 'Notificações', _settings.notificacoes ? 'Ativadas' : 'Desativadas',
                        onTap: () { _settings.toggleNotificacoes(); _audio.playTap(); },
                        trailing: Switch(
                          value: _settings.notificacoes,
                          onChanged: (_) { _settings.toggleNotificacoes(); _audio.playTap(); },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      _SettingData(Icons.access_alarm_outlined, 'Lembrete', _settings.lembreteLabel, onTap: _editarLembrete),
                    ])),
                    FadeInWidget(delayMs: 300, child: _buildGroup('Aparência', [
                      _SettingData(Icons.text_fields, 'Tamanho da fonte', _settings.tamanhoFonteLabel, onTap: _editarTamanhoFonte),
                      _SettingData(Icons.animation_outlined, 'Animações', _settings.animacoes ? 'Ativadas' : 'Desativadas',
                        onTap: () { _settings.toggleAnimacoes(); _audio.playTap(); },
                        trailing: Switch(
                          value: _settings.animacoes,
                          onChanged: (_) { _settings.toggleAnimacoes(); _audio.playTap(); },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      _SettingData(Icons.language, 'Idioma', 'Português (Brasil)'),
                    ])),
                    FadeInWidget(delayMs: 400, child: _buildGroup('Sons e Vibração', [
                      _SettingData(Icons.volume_up_outlined, 'Sons', _settings.sons ? 'Ativados' : 'Desativados',
                        onTap: () { _settings.toggleSons(); _audio.playTap(); },
                        trailing: Switch(
                          value: _settings.sons,
                          onChanged: (_) { _settings.toggleSons(); },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      _SettingData(Icons.vibration, 'Vibração', _settings.vibracao ? 'Ativada' : 'Desativada',
                        onTap: () { _settings.toggleVibracao(); _audio.playTap(); },
                        trailing: Switch(
                          value: _settings.vibracao,
                          onChanged: (_) { _settings.toggleVibracao(); },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ])),
                    FadeInWidget(delayMs: 450, child: _buildGroup('Formulário', [
                      _SettingData(Icons.phone_outlined, 'Seu número WhatsApp', _settings.numeroPsicologa.isEmpty ? 'Não configurado' : _settings.numeroPsicologa,
                        onTap: _editarNumeroPsicologa,
                      ),
                      _SettingData(Icons.message_outlined, 'Mensagem do formulário', 'Toque para editar',
                        onTap: _editarMensagemFormulario,
                      ),
                      _SettingData(Icons.link_outlined, 'Link do formulário', _settings.linkFormulario.isEmpty ? 'Não configurado' : _settings.linkFormulario,
                        onTap: _editarLinkFormulario,
                      ),
                    ])),
                    FadeInWidget(delayMs: 500, child: _buildGroup('Dados', [
                      _SettingData(Icons.cloud_upload_outlined, 'Exportar backup', 'Enviar arquivo com todas as consultas',
                        onTap: () => BackupService().exportar(context),
                      ),
                      _SettingData(Icons.cloud_download_outlined, 'Restaurar backup', 'Importar consultas de um arquivo',
                        onTap: () => BackupService().importar(context),
                      ),
                      _SettingData(Icons.delete_outline, 'Limpar consultas', 'Apagar todos os dados',
                        onTap: _limparConsultas,
                        danger: true,
                      ),
                    ])),
                    FadeInWidget(delayMs: 600, child: _buildGroup('Sobre', [
                      _SettingData(Icons.help_outline, 'Ajuda', 'Perguntas frequentes e suporte',
                        onTap: () => _abrirUrl('https://bemestar.com/ajuda'),
                      ),
                      _SettingData(Icons.description_outlined, 'Termos de Uso', 'Política de privacidade',
                        onTap: () => _abrirUrl('https://bemestar.com/termos'),
                      ),
                      _SettingData(Icons.info_outline, 'Sobre o app', 'BemEstar v1.0.0', onTap: _mostrarSobre),
                    ])),
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

  Widget _buildProfileCard() {
    return AnimatedCard(
      onTap: _editarPerfil,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            PulseWidget(
              minScale: 0.95,
              maxScale: 1.05,
              duration: const Duration(milliseconds: 3000),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_settings.nome, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(_settings.email, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(String title, List<_SettingData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8),
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: items.map((item) {
            return ListTile(
              onTap: item.onTap != null
                  ? () {
                      HapticFeedback.lightImpact();
                      _audio.playTap();
                      item.onTap!();
                    }
                  : null,
              leading: Icon(item.icon, color: item.danger == true ? AppColors.danger : AppColors.primary, size: 22),
              title: Text(item.label, style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: item.danger == true ? AppColors.danger : AppColors.textPrimary,
              )),
              subtitle: Text(item.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              trailing: item.trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SettingData {
  final IconData icon;
  final String label, description;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? danger;
  _SettingData(this.icon, this.label, this.description, {this.onTap, this.trailing, this.danger});
}
