import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_provider.dart';

class GlossaryWorkspace extends ConsumerStatefulWidget {
  final Project project;

  const GlossaryWorkspace({super.key, required this.project});

  @override
  ConsumerState<GlossaryWorkspace> createState() => _GlossaryWorkspaceState();
}

class _GlossaryWorkspaceState extends ConsumerState<GlossaryWorkspace>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _save() =>
      ref.read(libraryProvider.notifier).updateProject(widget.project);

  Future<void> _editCharacter([Character? character]) async {
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(character: character),
    );
    if (result == null) return;
    final index = widget.project.characters.indexWhere(
      (c) => c.id == result.id,
    );
    if (index == -1) {
      widget.project.characters.add(result);
    } else {
      widget.project.characters[index] = result;
    }
    _save();
    setState(() {});
  }

  Future<void> _editRelation([Relation? relation]) async {
    if (widget.project.characters.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two characters first.')),
      );
      return;
    }
    final result = await showDialog<Relation>(
      context: context,
      builder: (_) => _RelationDialog(
        relation: relation,
        characters: widget.project.characters,
      ),
    );
    if (result == null) return;
    final index = widget.project.relations.indexWhere((r) => r.id == result.id);
    if (index == -1) {
      widget.project.relations.add(result);
    } else {
      widget.project.relations[index] = result;
    }
    _save();
    setState(() {});
  }

  void _deleteCharacter(Character character) {
    widget.project.characters.removeWhere((c) => c.id == character.id);
    widget.project.relations.removeWhere(
      (r) => r.charA == character.id || r.charB == character.id,
    );
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.project.characters
        .where(
          (c) => '${c.originalName} ${c.translatedName} ${c.description}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    final names = {for (final c in widget.project.characters) c.id: c};

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Character Glossary & Relations',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Keep names and relationships consistent across your translation.',
                    style: TextStyle(color: Color(0xFF727785)),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _editCharacter(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add character'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0058BE),
            unselectedLabelColor: const Color(0xFF727785),
            indicatorColor: const Color(0xFF3B82F6),
            tabs: [
              Tab(text: 'Characters (${widget.project.characters.length})'),
              Tab(text: 'Relations (${widget.project.relations.length})'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search characters...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: characters.isEmpty
                          ? _emptyState(
                              'No characters found',
                              'Add a character to build your translation glossary.',
                            )
                          : ListView.separated(
                              itemCount: characters.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final character = characters[index];
                                return _CharacterCard(
                                  character: character,
                                  onEdit: () => _editCharacter(character),
                                  onDelete: () => _deleteCharacter(character),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _editRelation(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add relation'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: widget.project.relations.isEmpty
                          ? _emptyState(
                              'No relations yet',
                              'Connect characters to preserve story context.',
                            )
                          : ListView.separated(
                              itemCount: widget.project.relations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final relation =
                                    widget.project.relations[index];
                                final a =
                                    names[relation.charA]?.translatedName ??
                                    names[relation.charA]?.originalName ??
                                    'Unknown character';
                                final b =
                                    names[relation.charB]?.translatedName ??
                                    names[relation.charB]?.originalName ??
                                    'Unknown character';
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color(0xFFE1E2EC),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(
                                        Icons.account_tree_outlined,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      '$a  ↔  $b',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      relation.relationship.isEmpty
                                          ? 'Relationship not specified'
                                          : relation.relationship,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _editRelation(relation),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            widget.project.relations
                                                .removeWhere(
                                                  (r) => r.id == relation.id,
                                                );
                                            _save();
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_outlined, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      ],
    ),
  );
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CharacterCard({
    required this.character,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE1E2EC)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFD8E2FF),
        child: Text(
          character.originalName.isEmpty
              ? '?'
              : character.originalName[0].toUpperCase(),
        ),
      ),
      title: Text(
        character.translatedName.isEmpty
            ? character.originalName
            : character.translatedName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${character.originalName}${character.description.isEmpty ? '' : ' · ${character.description}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

class _CharacterDialog extends StatefulWidget {
  final Character? character;
  const _CharacterDialog({this.character});
  @override
  State<_CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<_CharacterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _original, _translated, _description;
  @override
  void initState() {
    super.initState();
    final c = widget.character;
    _original = TextEditingController(text: c?.originalName);
    _translated = TextEditingController(text: c?.translatedName);
    _description = TextEditingController(text: c?.description);
  }

  @override
  void dispose() {
    _original.dispose();
    _translated.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.character == null ? 'Add character' : 'Edit character'),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_original, 'Original name', required: true),
            _field(_translated, 'Translated name'),
            _field(_description, 'Description', maxLines: 3),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            Character(
              id:
                  widget.character?.id ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              originalName: _original.text.trim(),
              translatedName: _translated.text.trim(),
              description: _description.text.trim(),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );
}

class _RelationDialog extends StatefulWidget {
  final Relation? relation;
  final List<Character> characters;
  const _RelationDialog({this.relation, required this.characters});
  @override
  State<_RelationDialog> createState() => _RelationDialogState();
}

class _RelationDialogState extends State<_RelationDialog> {
  late String _a, _b;
  late final TextEditingController _relationship;
  @override
  void initState() {
    super.initState();
    _a = widget.relation?.charA ?? widget.characters.first.id;
    _b = widget.relation?.charB ?? widget.characters[1].id;
    _relationship = TextEditingController(text: widget.relation?.relationship);
  }

  @override
  void dispose() {
    _relationship.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.relation == null ? 'Add relation' : 'Edit relation'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _select('Character A', _a, (v) => setState(() => _a = v!)),
          _select('Character B', _b, (v) => setState(() => _b = v!)),
          TextField(
            controller: _relationship,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              hintText: 'e.g. mentor, sibling',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _a == _b
            ? null
            : () => Navigator.pop(
                context,
                Relation(
                  id:
                      widget.relation?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  charA: _a,
                  charB: _b,
                  relationship: _relationship.text.trim(),
                ),
              ),
        child: const Text('Save'),
      ),
    ],
  );
  Widget _select(String label, String value, ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: widget.characters
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    c.translatedName.isEmpty
                        ? c.originalName
                        : c.translatedName,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      );
}
