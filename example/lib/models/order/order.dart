import 'package:schemix/schemix.dart';

import '../user/user.dart';

part 'order.schemix.dart';

@Schemix(
  name: 'orders',
  schemaVersion: 1,
)
class Order {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @BelongsTo(User)
  final String userId;

  @DatabaseDefault('pending')
  final String status;

  @ReadOnlyField()
  @DatabaseGenerated(strategy: 'sequence')
  final int? orderNumber;

  @WriteOnlyField()
  @Encrypted()
  final String? creditCardToken;

  const Order({
    required this.id,
    required this.userId,
    this.status = 'pending',
    this.orderNumber,
    this.creditCardToken,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
  Order copy() => _$OrderCopy(this);
}
