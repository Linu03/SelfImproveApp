import 'package:hive/hive.dart';
part 'user_stats.g.dart';

@HiveType(typeId: 3)
class UserStats extends HiveObject {
  @HiveField(0)
  int totalXp;

  @HiveField(1)
  int level;

  UserStats({this.totalXp = 0, this.level = 1});
}
