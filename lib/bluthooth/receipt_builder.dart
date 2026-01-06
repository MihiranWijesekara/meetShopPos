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

    // Top margin
    bytes += generator.feed(3);

    // Shop Header
    bytes += generator.text(
      'DILANKA DISTRIBUTOR R W K',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'D.S ABEGUNAWARDANA MAWATHA KATUDENIYA OKANDAWATTA,MORAWAKA',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'TP : 07709109413',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Authorized Distributor For CRYSBRO Chicken',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Hotline : 077-2797276',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    bytes += generator.text(
      'SALES INVOICE',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    // Customer Info
    bytes += generator.text(
      'Customer : $shopName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      'Address : $rootName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      'Deliverd to : $shopName',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      'Inv.Date : $date',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      'Bill No: $billNo',
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();

    // Cart Items header with clearer spacing
    bytes += generator.hr(ch: '-');
    bytes += generator.row([
      PosColumn(text: '', width: 1), // left padding for centering
      PosColumn(text: 'Item', width: 5, styles: PosStyles(bold: true)),
      PosColumn(
        text: 'Weight',
        width: 3,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: 'Rate',
        width: 3,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr(ch: '-');

    // Cart Items data
    for (final item in cartItems) {
      bytes += generator.row([
        PosColumn(text: '', width: 1), // left padding for centering
        PosColumn(text: item.itemName, width: 5),
        PosColumn(
          text: '${item.weight.toStringAsFixed(2)}kg',
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'RS ${item.amount.toStringAsFixed(2)}',
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
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

    bytes += generator.feed(4); // Adds extra bottom height for tear space

    // Footer Section
    bytes += generator.text(
      "Sales rep : MADURA WATHTHAGE F",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.text(
      "Original Print Printed on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();
    bytes += generator.text(
      "-------Thank you----",
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(3);

    return bytes;
  }
}
