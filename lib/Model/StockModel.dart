class StockModel{
  final int? id;
  final int item_id;
  final int stock_price;
  final int? quantity_kg;
  final double? remain_quantity;
  final String? added_date;
StockModel({
  this.id,
  required this.item_id,
  required this.stock_price,
  this.quantity_kg,
  this.remain_quantity,
  this.added_date,
});

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'item_id': item_id,
    'stock_price': stock_price,
    'quantity_kg': quantity_kg,
    'remain_quantity': remain_quantity,
    'added_date': added_date,
  };
}
factory StockModel.fromMap(Map<String, dynamic> map) {
  return StockModel(
    id: map['id'],
    item_id: map['item_id'],
    stock_price: map['stock_price'],
    quantity_kg: map['quantity_kg'],
    remain_quantity: map['remain_quantity'],
    added_date: map['added_date'],
  );
}

}