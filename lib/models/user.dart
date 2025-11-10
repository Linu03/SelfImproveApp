// import 'package:flutter/material.dart';
// import './models/task.dart';
import 'skill_category.dart';
import 'task.dart';

class User {
  String id;
  String username;    // custom name of user
  String avatarUrl;   // link to avatar image
  int hpBar;          // health points
  int xpBar;          // experience points
  List<SkillCategory> skills;  // list of user skills
  List<Task> tasks;   // list of user tasks



  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.xpBar = 0,
    this.hpBar = 100,
    this.skills = const [],
    this.tasks = const [],
  });
}
