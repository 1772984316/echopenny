import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/personas.dart';

part 'persona_dao.g.dart';

@DriftAccessor(tables: [Personas])
class PersonaDao extends DatabaseAccessor<AppDatabase> with _$PersonaDaoMixin {
  PersonaDao(super.db);

  Future<List<Persona>> getAllPersonas() {
    return select(personas).get();
  }

  Future<Persona?> getDefaultPersona() {
    return (select(personas)..where((p) => p.isDefault.equals(true))).getSingleOrNull();
  }

  Future<int> createPersona(PersonasCompanion entry) {
    return into(personas).insert(entry);
  }

  Future<bool> setDefault(int id) {
    return transaction(() async {
      await (update(personas)..where((p) => p.isDefault.equals(true)))
          .write(const PersonasCompanion(isDefault: Value(false)));
      await (update(personas)..where((p) => p.id.equals(id)))
          .write(const PersonasCompanion(isDefault: Value(true)));
      return true;
    });
  }
}
