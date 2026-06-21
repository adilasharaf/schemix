import 'package:schemix/schemix.dart';

import '../user/user.dart';

part 'profile.schemix.dart';

@Schemix(
  name: 'profiles',
  schemaVersion: 1,
)
class Profile {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @BelongsTo(User)
  @Unique()
  final String userId;

  @Url()
  final String? website;

  @Regex(r'^\+?[1-9]\d{1,14}$')
  final String? phoneNumber;

  @DatabaseDefault(true)
  final bool isActive;

  @CheckConstraint('age >= 18')
  @Min(18)
  final int? age;

  const Profile({
    required this.id,
    required this.userId,
    this.website,
    this.phoneNumber,
    this.isActive = true,
    this.age,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
  Profile copy() => _$ProfileCopy(this);
}
