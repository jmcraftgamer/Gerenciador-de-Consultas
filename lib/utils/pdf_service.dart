import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/consulta.dart';
import '../models/consulta_service.dart';

// dart:io conditional import for web compatibility
import 'pdf_service_io.dart' if (dart.library.js_interop) 'pdf_service_web.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _service = ConsultaService();

  List<Consulta> _obterConsultas(String periodo) {
    final now = DateTime.now();
    switch (periodo) {
      case 'dia':
        return _service.consultasPorData(now);
      case 'semana':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return _service.consultasOrdenadas().where((c) {
          return !c.data.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) &&
              !c.data.isAfter(DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59));
        }).toList();
      case 'mes':
        return _service.consultasOrdenadas().where((c) {
          return c.data.year == now.year && c.data.month == now.month;
        }).toList();
      default:
        return _service.consultasOrdenadas();
    }
  }

  String _periodoLabel(String periodo) {
    switch (periodo) {
      case 'dia':
        return 'Consultas do Dia';
      case 'semana':
        return 'Consultas da Semana';
      case 'mes':
        return 'Consultas do Mês';
      default:
        return 'Todas as Consultas';
    }
  }

  Future<pw.Document> gerarPdf(String periodo) async {
    final consultas = _obterConsultas(periodo);
    final pdf = pw.Document();
    final now = DateTime.now();
    final meses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final dataAtual = '${now.day} de ${meses[now.month]} de ${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BemEstar',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#3D3428'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Psicanalista ao seu lado',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#8A7D6B'),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _periodoLabel(periodo),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#B8A88A'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Gerado em: $dataAtual',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromHex('#8A7D6B'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 2,
              color: PdfColor.fromHex('#B8A88A'),
            ),
            pw.SizedBox(height: 15),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Container(
              height: 1,
              color: PdfColor.fromHex('#E5DDD1'),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BemEstar - Gerenciador de Consultas',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#8A7D6B')),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#8A7D6B')),
                ),
              ],
            ),
          ],
        ),
        build: (context) {
          if (consultas.isEmpty) {
            return [
              pw.SizedBox(height: 60),
              pw.Center(
                child: pw.Text(
                  'Nenhuma consulta encontrada para este período.',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColor.fromHex('#8A7D6B'),
                  ),
                ),
              ),
            ];
          }

          final List<pw.Widget> widgets = [];

          // Summary box
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8F5EF'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total', '${consultas.length}'),
                  _buildSummaryItem('Presenciais', '${consultas.where((c) => c.modalidade == 'Presencial').length}'),
                  _buildSummaryItem('Online', '${consultas.where((c) => c.modalidade == 'Online').length}'),
                  _buildSummaryItem('Confirmadas', '${consultas.where((c) => c.confirmada).length}'),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Table
          widgets.add(
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#FFFFFF')),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#B8A88A')),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 32,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
              },
              headerAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
              },
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#E5DDD1'), width: 0.5),
              ),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              headers: ['Paciente', 'Data', 'Horário', 'Telefone', 'Modalidade', 'Status'],
              data: consultas.map((c) => [
                c.paciente,
                c.dataFormatada,
                c.horarioFormatado,
                c.telefone.isNotEmpty ? c.telefone : '—',
                c.modalidade,
                c.confirmada ? 'Confirmada' : 'Pendente',
              ]).toList(),
            ),
          );

          // Detailed cards for each consultation
          widgets.add(pw.SizedBox(height: 25));
          widgets.add(
            pw.Text(
              'Detalhes das Consultas',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#3D3428'),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 10));

          for (final c in consultas) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E5DDD1'), width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          c.paciente,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#3D3428')),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: c.confirmada ? PdfColor.fromHex('#F0EBE3') : PdfColor.fromHex('#F5F0E8'),
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Text(
                            c.confirmada ? 'Confirmada' : 'Pendente',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: c.confirmada ? PdfColor.fromHex('#3D3428') : PdfColor.fromHex('#B8A07A'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Text('Data: ${c.dataFormatada}  |  Horário: ${c.horarioFormatado}',
                          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#8A7D6B')),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        if (c.telefone.isNotEmpty)
                          pw.Text('Telefone: ${c.telefone}  |  ',
                            style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#8A7D6B')),
                          ),
                        pw.Text('Modalidade: ${c.modalidade}',
                          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#8A7D6B')),
                        ),
                      ],
                    ),
                    if (c.queixas.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Queixas: ${c.queixas.join(', ')}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#8A7D6B')),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#3D3428'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#8A7D6B'),
          ),
        ),
      ],
    );
  }

  Future<void> baixarPdf(String periodo, {pw.Document? existingPdf}) async {
    final pdf = existingPdf ?? await gerarPdf(periodo);
    final bytes = await pdf.save();
    final filename = 'bemestar_${periodo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await savePdfToFile(bytes, filename);
  }

  Future<void> imprimirPdf(String periodo, {pw.Document? existingPdf}) async {
    final pdf = existingPdf ?? await gerarPdf(periodo);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BemEstar - ${_periodoLabel(periodo)}',
    );
  }

  Future<void> compartilharPdf(String periodo, {pw.Document? existingPdf}) async {
    final pdf = existingPdf ?? await gerarPdf(periodo);
    final bytes = await pdf.save();
    final filename = 'bemestar_${periodo}.pdf';
    await sharePdfFile(bytes, filename, 'Relatório de consultas - ${_periodoLabel(periodo)}', 'BemEstar - Relatório');
  }
}
