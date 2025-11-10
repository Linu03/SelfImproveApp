class SkillCategory {
  String id;
  String name;       // numele categoriei de skill
  int xp;            
  int level;         
  


  SkillCategory({
    required this.id,
    required this.name,
    this.xp = 0,
    this.level = 1,
  });
}
