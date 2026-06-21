import 'package:schemix/schemix.dart';

import '../category/category.dart';
import '../tag/tag.dart';
import '../user/user.dart';

part 'post.schemix.dart';

enum PostStatus { draft, published, archived }

@Schemix(
  name: 'posts',
  schemaVersion: 1,
  enableTimestamps: true,
  enableSoftDelete: true,
)
class Post {
  @PrimaryKey(autoGenerate: true)
  String id;

  @Length(min: 1, max: 255)
  String? title;

  @FullTextSearch()
  @SchemixField(searchable: true)
  String? body;

  @DatabaseGenerated(strategy: 'uuid')
  String? slug;

  @DatabaseDefault(PostStatus.draft)
  PostStatus status = PostStatus.draft;

  @BelongsTo(User)
  String? userId;

  @BelongsTo(Category)
  String? categoryId;

  @ManyToMany(Tag, junctionTable: 'post_tags')
  List<Tag> tags = [];

  Post({required this.id});

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
  Post copy() => _$PostCopy(this);
}

// class Pop {
//   final post = Post(id: "");

//   void doSomething() {
//     Post.
//   }
// }
