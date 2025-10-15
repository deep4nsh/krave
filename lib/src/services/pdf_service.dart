// lib/services/pdf_service.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfService {
  Future<Uint8List> generateBillPdf({
    required String orderId,
    required String canteenName,
    required String token,
    required List<Map<String, dynamic>> items,
    required int total,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(children: [
            pw.Text('KRAVE - Bill', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text('Order ID: $orderId'),
            pw.Text('Canteen: $canteenName'),
            pw.Text('Token: $token'),
            pw.SizedBox(height: 10),
pw.TableHelper.fromTextArray(data: <List<String>>[
              <String>['Item', 'Qty', 'Price'],
              ...items.map((i) => [i['name'].toString(), i['qty'].toString(), '₹${i['price']}']),
            ]),
            pw.Divider(),
            pw.Text('Total: ₹$total', style: pw.TextStyle(fontSize: 18)),
          ]);
        },
      ),
    );
    return pdf.save();
  }

  Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}