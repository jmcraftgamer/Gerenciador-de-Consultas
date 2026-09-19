import 'package:url_launcher/url_launcher.dart';
import 'settings_service.dart';

Future<void> enviarFormulario(String telefonePaciente, String nomePaciente) async {
  final settings = SettingsService();
  final link = settings.linkFormulario;
  var mensagem = settings.mensagemFormulario;

  if (link.isEmpty || telefonePaciente.isEmpty) return;

  mensagem = mensagem.replaceAll('{nome}', nomePaciente);
  mensagem = mensagem.replaceAll('{link}', link);

  final numero = telefonePaciente.replaceAll(RegExp(r'[^0-9]'), '');
  if (numero.isEmpty) return;

  final fullNumero = numero.startsWith('55') ? numero : '55$numero';
  final encodedMsg = Uri.encodeComponent(mensagem);
  final url = Uri.parse('https://wa.me/$fullNumero?text=$encodedMsg');

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
