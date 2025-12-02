import 'package:hive/hive.dart';
part 'category_xp.g.dart';

@HiveType(typeId: 5)
class CategoryXp extends HiveObject {
  @HiveField(0)
  String categoryName;

  @HiveField(1)
  int totalXp;

  @HiveField(2)
  int level;

  CategoryXp({required this.categoryName, this.totalXp = 0, this.level = 1});
}
