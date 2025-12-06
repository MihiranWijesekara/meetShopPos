import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:chicken_dilivery/Model/CartItemModel.dart';

class ReceiptBuilder {
  static Future<List<int>> buildReceipt({
    required String shopName,
    required String billNo,
    required String date,
    required List<CartItem> cartItems,
    required double totalAmount,
    required String rootName, 
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    // Shop Header
    bytes += generator.text('DILANKA DISTRIBUTOR R W K',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('D.S ABEGUNAWARDANA MAWATHA KATUDENIYA OKANDAWATTA,MORAWAKA',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('TP : 07709109413',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Authorized Distributor For CRYSBRO Chicken',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Hotline : 077-2797276',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.text('SALES INVOICE',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr();

    // Customer Info
    bytes += generator.text('Customer : $shopName',
        styles: PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text('Address : $rootName',
        styles: PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text('Deliverd to : $shopName',
        styles: PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text('Inv.Date : $date',
        styles: PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text('Bill No: $billNo',
        styles: PosStyles(align: PosAlign.left));
    bytes += generator.hr();

    // Cart Items
    for (final item in cartItems) {
      bytes += generator.row([
        PosColumn(text: item.itemName, width: 4),
        PosColumn(text: '${item.weight.toStringAsFixed(2)}kg', width: 4, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: 'RS ${item.amount.toStringAsFixed(2)}', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.text("TOTAL: RS ${totalAmount.toStringAsFixed(2)}",
        styles: PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.feed(2);

    return bytes;
  }
}
