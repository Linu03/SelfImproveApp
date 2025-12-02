import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  List<int>? avatarBytes;

  UserProfile({this.username = 'Player', this.avatarBytes});
}
