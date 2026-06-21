import 'package:schemix/schemix.dart';

import '../post/post.dart';

part 'category.schemix.dart';

enum CategoryType { standard, premium, internal }

@Schemix(name: 'categories', schemaVersion: 1)
class Category {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Indexed(unique: true)
  @Length(min: 3, max: 100)
  final String name;

  @EnumFallback(CategoryType.standard)
  @DatabaseDefault(CategoryType.standard)
  final CategoryType type;

  @HasMany(Post)
  final List<Post> posts;

  const Category({
    required this.id,
    required this.name,
    this.type = CategoryType.standard,
    this.posts = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
  Category copy() => _$CategoryCopy(this);
}
