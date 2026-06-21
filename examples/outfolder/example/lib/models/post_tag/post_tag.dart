import 'package:schemix/schemix.dart';

import '../post/post.dart';
import '../tag/tag.dart';

part 'post_tag.schemix.dart';

@Schemix(
  name: 'post_tags',
  schemaVersion: 1,
)
@CompositeIndex(fields: ['postId', 'tagId'], unique: true)
class PostTag {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @BelongsTo(Post)
  final String postId;

  @BelongsTo(Tag)
  final String tagId;

  // The relation instances
  @HasOne(Post)
  final Post? post;

  @HasOne(Tag)
  final Tag? tag;

  const PostTag({
    required this.id,
    required this.postId,
    required this.tagId,
    this.post,
    this.tag,
  });

  factory PostTag.fromJson(Map<String, dynamic> json) => _$PostTagFromJson(json);
  Map<String, dynamic> toJson() => _$PostTagToJson(this);
  PostTag copy() => _$PostTagCopy(this);
}
