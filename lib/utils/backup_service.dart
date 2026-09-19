import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';
import '../utils/settings_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Map<String, dynamic> _buildBackupData() {
    final service = ConsultaService();
    final settings = SettingsService();
    return {
      'versao': 1,
      'dataExportacao': DateTime.now().toIso8601String(),
      'consultas': service.consultas.map((c) => c.toJson()).toList(),
      'configuracoes': {
        'nome': settings.nome,
        'email': settings.email,
        'numeroPsicologa': settings.numeroPsicologa,
        'mensagemFormulario': settings.mensagemFormulario,
        'linkFormulario': settings.linkFormulario,
        'lembreteMinutos': settings.lembreteMinutos,
        'sons': settings.sons,
        'vibracao': settings.vibracao,
        'animacoes': settings.animacoes,
        'tamanhoFonte': settings.tamanhoFonte,
      },
    };
  }

  Future<void> exportar(BuildContext context) async {
    try {
      final data = _buildBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      if (kIsWeb) {
        await Share.share(jsonStr, subject: 'Backup BemEstar');
      } else {
        await Share.share(jsonStr, subject: 'Backup BemEstar');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup exportado!', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> importar(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;

      String jsonStr;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        jsonStr = utf8.decode(bytes);
      } else {
        final data = result.files.first.bytes;
        if (data == null) return;
        jsonStr = utf8.decode(data);
      }

      final backupData = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (backupData['versao'] == null || backupData['consultas'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arquivo inválido', style: GoogleFonts.inter()), backgroundColor: Colors.red.shade700),
          );
        }
        return;
      }

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFF8F5EF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Restaurar backup?', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Text('Substituir todas as consultas e configurações?', style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.grey.shade600))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Restaurar', style: GoogleFonts.inter(color: const Color(0xFFB8A88A), fontWeight: FontWeight.w600))),
          ],
        ),
      );

      if (confirmar != true) return;

      final service = ConsultaService();
      service.limparTodas();

      final consultasJson = backupData['consultas'] as List<dynamic>;
      for (final cJson in consultasJson) {
        service.adicionar(Consulta.fromJson(cJson as Map<String, dynamic>));
      }

      final config = backupData['configuracoes'] as Map<String, dynamic>?;
      if (config != null) {
        final settings = SettingsService();
        if (config['nome'] != null) await settings.atualizarPerfil(nome: config['nome'], email: config['email'] ?? settings.email);
        if (config['numeroPsicologa'] != null) await settings.setNumeroPsicologa(config['numeroPsicologa']);
        if (config['mensagemFormulario'] != null) await settings.setMensagemFormulario(config['mensagemFormulario']);
        if (config['linkFormulario'] != null) await settings.setLinkFormulario(config['linkFormulario']);
        if (config['lembreteMinutos'] != null) await settings.setLembreteMinutos(config['lembreteMinutos']);
        if (config['tamanhoFonte'] != null) await settings.setTamanhoFonte((config['tamanhoFonte'] as num).toDouble());
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restaurado! ${consultasJson.length} consultas.', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }
}
