import 'package:hive/hive.dart';

part 'reward_item.g.dart';

@HiveType(typeId: 7)
class RewardItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int price;

  @HiveField(2)
  int? durationMinutes;

  @HiveField(3)
  String category;

  RewardItem({
    required this.name,
    required this.price,
    this.durationMinutes,
    required this.category,
  });

  /// Create a copy of this reward (detached from Hive)
  RewardItem copy() {
    return RewardItem(
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      category: category,
    );
  }
}
