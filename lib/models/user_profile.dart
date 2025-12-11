import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  List<int>? avatarBytes;

  @HiveField(2)
  int coins;

  @HiveField(3)
  int entertainmentMinutes;

  UserProfile({
    this.username = 'Player',
    this.avatarBytes,
    this.coins = 0,
    this.entertainmentMinutes = 0,
  });
}
