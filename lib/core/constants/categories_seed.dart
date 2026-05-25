class CategorySeed {
  final String name;
  final String icon;
  final List<String> children;

  const CategorySeed({required this.name, required this.icon, required this.children});
}

const defaultCategories = <CategorySeed>[
  CategorySeed(name: '餐饮', icon: '🍜', children: ['早餐', '午餐', '晚餐', '夜宵', '零食', '饮品', '外卖']),
  CategorySeed(name: '交通', icon: '🚇', children: ['地铁', '公交', '打车', '加油', '停车']),
  CategorySeed(name: '购物', icon: '🛒', children: ['日用品', '服饰', '数码', '美妆']),
  CategorySeed(name: '住房', icon: '🏠', children: ['房租', '水费', '电费', '燃气', '物业']),
  CategorySeed(name: '娱乐', icon: '🎮', children: ['游戏', '电影', '音乐', '旅行']),
  CategorySeed(name: '医疗', icon: '🏥', children: ['门诊', '药品', '体检']),
  CategorySeed(name: '教育', icon: '📚', children: ['书籍', '课程', '考试']),
  CategorySeed(name: '社交', icon: '🎉', children: ['聚餐', '礼物', '红包']),
  CategorySeed(name: '通讯', icon: '📱', children: ['话费', '网费', '会员']),
  CategorySeed(name: '宠物', icon: '🐱', children: ['食物', '医疗', '用品']),
  CategorySeed(name: '其他', icon: '📌', children: []),
];
