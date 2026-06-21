import 'package:schemix/schemix.dart';

import '../post/post.dart';
import '../profile/profile.dart';

part 'user.schemix.dart';

@CompositeIndex(fields: ['email', 'displayName'])
@SchemaGroup('auth')
@SchemaDescription('Represents a system user')
@Schemix(
  name: 'users',
  schemaVersion: 1,
  enableTimestamps: true,
  enableSoftDelete: true,
)
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Email()
  @Indexed(unique: true)
  @Length(max: 255)
  final String email;

  @Hashed()
  final String passwordHash;

  @SchemixField(displayName: 'Display Name')
  @Length(max: 100)
  final String? displayName;

  @HasMany(Post)
  final List<Post> posts;

  @HasOne(Profile)
  final Profile? profile;

  @SqlType('JSONB')
  @TsType('Record<string, unknown>')
  final Map<String, dynamic>? metadata;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.displayName,
    this.posts = const [],
    this.profile,
    this.metadata,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  User copy() => _$UserCopy(this);
}
