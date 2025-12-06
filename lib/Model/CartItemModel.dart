// Cart Item Model
class CartItem {
  final int itemId;
  final String itemName;
  final double sellingPrice;
  double weight;
  double amount;

  CartItem({
    required this.itemId,
    required this.itemName,
    required this.sellingPrice,
    required this.weight,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'sellingPrice': sellingPrice,
      'weight': weight,
      'amount': amount,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: map['itemId'],
      itemName: map['itemName'],
      sellingPrice: map['sellingPrice'],
      weight: map['weight'],
      amount: map['amount'],
    );
  }
}