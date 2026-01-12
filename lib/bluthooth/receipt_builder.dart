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
    bytes += generator.text(
      'DILANKA DISTRIBUTOR R W K',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(2); // Adds height

    bytes += generator.text(
      'D.S ABEGUNAWARDANA MAWATHA KATUDENIYA OKANDAWATTA,MORAWAKA',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'TP : 07709109413',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Authorized Distributor For CRYSBRO Chicken',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Hotline : 077-2797276',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2); // Adds height

    bytes += generator.hr();
    bytes += generator.text(
      'SALES INVOICE',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();
    bytes += generator.feed(2); // Adds height
    // Customer Info
    bytes += generator.text(
      'Customer : $shopName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Address : $rootName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Deliverd to : $shopName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Inv.Date : $date',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.text(
      'Bill No: $billNo',
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();
    bytes += generator.feed(2); // Adds height

    // Cart Items header with clearer spacing
    bytes += generator.hr(ch: '-');
    bytes += generator.row([
      PosColumn(text: 'Item', width: 4, styles: PosStyles(bold: true)),
      PosColumn(
        text: 'Weight',
        width: 2,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: 'Rate',
        width: 3,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: 'Total',
        width: 3,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr(ch: '-');
    int index = 1;

    for (final item in cartItems) {
      double itemTotal = item.amount;

      bytes += generator.row([
        PosColumn(text: '$index. ${item.itemName}', width: 4),
        PosColumn(
          text: '${item.weight.toStringAsFixed(2)}',
          width: 2,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'RS ${item.amount.toStringAsFixed(2)}',
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: itemTotal.toStringAsFixed(2),
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);

      // Add a small spacer line after each item to increase receipt height
      bytes += generator.text(' ');

      index++;
    }

    bytes += generator.hr();
    double totalDiscount = cartItems.fold(
      0.0,
      (sum, item) => sum + item.discount,
    );

    bytes += generator.text(
      "TOTAL: RS ${totalAmount.toStringAsFixed(2)}",
      styles: PosStyles(align: PosAlign.right, bold: true),
    );
    bytes += generator.text(
      "TOTAL DISCOUNT: RS ${totalDiscount.toStringAsFixed(2)}",
      styles: PosStyles(align: PosAlign.right, bold: true),
    );

    bytes += generator.feed(2); // Adds height

    bytes += generator.text(
      "Original Print Printed on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.feed(2); // Adds height
    bytes += generator.hr();
    bytes += generator.text(
      "-------Thank you----",
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(3);

    return bytes;
  }
}
