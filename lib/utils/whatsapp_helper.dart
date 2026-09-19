import 'package:url_launcher/url_launcher.dart';

Future<void> abrirWhatsApp(String telefone) async {
  final numero = telefone.replaceAll(RegExp(r'[^0-9]'), '');
  if (numero.isEmpty) return;
  final fullNumero = numero.startsWith('55') ? numero : '55$numero';
  final url = Uri.parse('https://wa.me/$fullNumero');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
