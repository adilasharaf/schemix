import 'package:schemix/schemix.dart';

part 'product.schemix.dart';

@Schemix(
  name: 'products',
  schemaVersion: 1,
)
class Product {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Length(max: 150)
  final String name;

  @Precision(precision: 10, scale: 2)
  @Min(0.0)
  final double price;

  @Min(0)
  @Max(10000)
  @DatabaseDefault(0)
  final int stock;

  @AllowedValues(['physical', 'digital'])
  @DatabaseDefault('physical')
  final String type;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.stock = 0,
    this.type = 'physical',
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
  Product copy() => _$ProductCopy(this);
}
