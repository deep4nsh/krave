import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class PdfInvoiceService {
  Future<Uint8List> createInvoice(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildOrderDetails(order),
              pw.SizedBox(height: 30),
              _buildInvoiceTable(order),
              pw.SizedBox(height: 30),
              _buildTotal(order),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Krave Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date: ${DateFormat.yMMMd().format(DateTime.now())}'),
      ],
    );
  }

  pw.Widget _buildOrderDetails(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Order ID: ${order.id}'),
        pw.Text('Token Number: ${order.tokenNumber}'),
        pw.Text('Order Date: ${DateFormat.yMMMd().add_jm().format(order.timestamp)}'),
      ],
    );
  }

  pw.Widget _buildInvoiceTable(OrderModel order) {
    final headers = ['Item', 'Quantity', 'Price', 'Total'];
    final data = order.items.map((item) => [
      item['name'],
      item['quantity'].toString(),
      'Rs. ${item['price']}',
      'Rs. ${item['price'] * item['quantity']}',
    ]).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  pw.Widget _buildTotal(OrderModel order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'Grand Total: Rs. ${order.totalAmount}',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text('Thank you for your order!', style: const pw.TextStyle(fontSize: 12)),
    );
  }

  Future<void> saveAsPdf(OrderModel order) async {
    final bytes = await createInvoice(order);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
