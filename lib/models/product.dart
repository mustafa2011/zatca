const String tableProducts = 'products';

class ProductFields {
  static const String id = 'id';
  static const String productName = 'productName';
  static const String price = 'price';

  static List<String> getProductsFields() =>
      [id, productName, price];
}

class Product {
  int? id;
  String? productName;
  num? price;

  Product({this.id,
    this.productName,
    this.price,
  });

  Product copy({
    int? id,
    String? productName,
    num? price,
  }) =>
      Product(
        id: id ?? this.id,
        productName: productName ?? this.productName,
        price: price ?? this.price,
      );

  factory Product.fromJson(dynamic json) {
    return Product(
      id: json[ProductFields.id] as int,
      productName: json[ProductFields.productName],
      price: json[ProductFields.price] as num,
    );
  }

  Map<String, dynamic> toJson() =>
      {
        ProductFields.id: id,
        ProductFields.productName: productName,
        ProductFields.price: price,
      };


}

