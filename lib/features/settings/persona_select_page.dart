import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../shared/providers/app_providers.dart';

class PersonaSelectPage extends ConsumerStatefulWidget {
  const PersonaSelectPage({super.key});

  @override
  ConsumerState<PersonaSelectPage> createState() => _PersonaSelectPageState();
}

class _PersonaSelectPageState extends ConsumerState<PersonaSelectPage> {
  List<Persona> _personas = [];
  int? _defaultId;

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    final db = ref.read(databaseProvider);
    final personas = await db.personaDao.getAllPersonas();
    final defaultPersona = await db.personaDao.getDefaultPersona();
    setState(() { _personas = personas; _defaultId = defaultPersona?.id; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择人设')),
      body: ListView.builder(
        itemCount: _personas.length,
        itemBuilder: (context, index) {
          final persona = _personas[index];
          final isCurrent = persona.id == _defaultId;
          return ListTile(
            leading: CircleAvatar(child: Text(persona.avatar.isNotEmpty ? persona.avatar : persona.name.substring(0, 1))),
            title: Text(persona.name),
            subtitle: Text(persona.systemPrompt.length > 50 ? '${persona.systemPrompt.substring(0, 50)}...' : persona.systemPrompt),
            trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: isCurrent ? null : () async {
              final db = ref.read(databaseProvider);
              await db.personaDao.setDefault(persona.id);
              _loadPersonas();
            },
          );
        },
      ),
    );
  }
}
