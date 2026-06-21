import 'package:schemix/schemix.dart';

import '../post_tag/post_tag.dart';

part 'tag.schemix.dart';

@Schemix(
  name: 'tags',
  schemaVersion: 1,
  enableTimestamps: false,
  enableSoftDelete: false,
)
class Tag {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Unique()
  @Length(min: 1, max: 50)
  final String name;

  @SchemixField(description: 'URL-friendly identifier for the tag')
  @Unique()
  final String slug;

  @HasMany(PostTag)
  final List<PostTag> posts;

  const Tag({required this.id, required this.name, required this.slug, this.posts = const []});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);

  Tag copy() => _$TagCopy(this);
}
