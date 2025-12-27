class ItemModel {
  final int? id;
  final String name;
  final String? shortCode;
  final double price;

  ItemModel({this.id, required this.name, this.shortCode, required this.price});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'short_code': shortCode, 'price': price};
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      shortCode: map['short_code'],
      price: map['price'],
    );
  }
}
