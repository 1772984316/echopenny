import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
  }

  Future<List<Category>> getSubCategories(int parentId) {
    return (select(categories)..where((c) => c.parentId.equals(parentId))).get();
  }

  Future<int> createCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }
}
