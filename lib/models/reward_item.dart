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

  // Whether this reward is currently active (counting down)
  @HiveField(4)
  bool isActive;

  // The moment when the active countdown started
  @HiveField(5)
  DateTime? startTime;

  // Remaining minutes at the time of activation (or remaining minutes when last saved)
  @HiveField(6)
  int remainingMinutes;

  RewardItem({
    required this.name,
    required this.price,
    this.durationMinutes,
    required this.category,
    this.isActive = false,
    this.startTime,
    int? remainingMinutes,
  }) : remainingMinutes = remainingMinutes ?? (durationMinutes ?? 0);

  /// Create a copy of this reward (detached from Hive)
  /// When copying for a new purchase, ensure the copy is inactive and
  /// has the full available duration saved in `remainingMinutes`.
  RewardItem copy() {
    return RewardItem(
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      category: category,
      isActive: false,
      startTime: null,
      remainingMinutes: durationMinutes ?? 0,
    );
  }
}
