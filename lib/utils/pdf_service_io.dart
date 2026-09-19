import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> savePdfToFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
}

Future<void> sharePdfFile(List<int> bytes, String filename, String text, String subject) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path)],
    text: text,
    subject: subject,
  );
}
