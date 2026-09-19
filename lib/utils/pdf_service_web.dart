import 'package:share_plus/share_plus.dart';

Future<void> savePdfToFile(List<int> bytes, String filename) async {
  // On web, saving to file system is not supported
  // This is a no-op; download is handled via Printing.layoutPdf
}

Future<void> sharePdfFile(List<int> bytes, String filename, String text, String subject) async {
  await Share.share(
    'Relatório de consultas BemEstar',
    subject: subject,
  );
}
