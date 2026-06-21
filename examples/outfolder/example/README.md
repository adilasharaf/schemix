# example — Schemix Example

This example demonstrates every major Schemix feature using three models: `User`, `Post`, and `Tag`. Running `build_runner build` generates Drift tables, Drizzle schemas, Zod schemas, TypeScript interfaces, and Dart JSON serialization from the single annotated source files.

---

## Models

| Model  | Generators active                    | Key features                                                                       |
| ------ | ------------------------------------ | ---------------------------------------------------------------------------------- |
| `User` | Drift · Drizzle · Zod · Serializable | UUID PK, `@Email`, `@Hashed`, timestamps, soft-delete, `@HasMany(Post)`            |
| `Post` | Drift · Drizzle · Zod · Serializable | `@BelongsTo(User)`, `@ManyToMany(Tag)`, `PostStatus` enum, timestamps, soft-delete |
| `Tag`  | Zod only                             | Minimal model, unique `name` + `slug`, no timestamps                               |

---

## Running the example

```bash
# From the repo root
dart pub get --directory examples/example
cd examples/example
dart run build_runner build --delete-conflicting-outputs
```

---

## Expected outputs

```
lib/
  models/
    user.schemix.dart       ← Dart JSON serialization for User
    user.table.dart         ← Drift Table subclass for User
    post.schemix.dart       ← Dart JSON serialization for Post
    post.table.dart         ← Drift Table subclass for Post
    tag.schemix.dart        ← Dart JSON serialization for Tag
gen/
  models/
    user.g.ts               ← Zod schema + TypeScript interface for User
    user.drizzle.ts         ← Drizzle pgTable for User
    post.g.ts               ← Zod schema + TypeScript interface for Post
    post.drizzle.ts         ← Drizzle pgTable + relations for Post
    tag.g.ts                ← Zod schema + TypeScript interface for Tag
  schemix.g.ts              ← Barrel re-export of all .g.ts files
```

---

## Annotation highlights

### User — UUID PK, timestamps, soft-delete

```dart
@Schemix(
  tableName: 'users',
  enableTimestamps: true,   // injects createdAt / updatedAt
  enableSoftDelete: true,   // injects nullable deletedAt
)
class User {
  @PrimaryKey(autoGenerate: true)  // UUID v4 clientDefault
  final String id;

  @Email()
  @Indexed(unique: true)
  final String email;

  @Hashed()                        // excluded from toJson output
  final String passwordHash;
}
```

### Post — relations and enum

```dart
@Schemix(tableName: 'posts', enableTimestamps: true, ...)
class Post {
  @BelongsTo(User)          // emits userId FK column
  final String userId;

  @ManyToMany(Tag, junctionTable: 'post_tags')
  final List<Tag> tags;     // no column; junction table only

  @DatabaseDefault(PostStatus.draft)
  final PostStatus status;  // enum → IntColumn in Drift, text enum in Drizzle
}
```

### Tag — Zod only

```dart
@Schemix(
)
class Tag {
  @Unique()
  final String slug;
}
```
