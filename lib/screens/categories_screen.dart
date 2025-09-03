import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _showSupCatForm(
    BuildContext context, {
    String? docId,
    SupCatModel? supCat,
  }) async {
    final isNew = supCat == null;
    final nameCtrl = TextEditingController(text: supCat?.name ?? '');
    final formKey = GlobalKey<FormState>();
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    // List of child categories (name + image)
    List<Map<String, TextEditingController>> childCtrls =
        (supCat?.categories ?? [])
            .map(
              (c) => {
                'name': TextEditingController(text: c.name),
                'image': TextEditingController(text: c.image),
              },
            )
            .toList();

    void addChild() {
      childCtrls.add({
        'name': TextEditingController(),
        'image': TextEditingController(),
      });
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Add Category' : 'Edit Category'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Main Category Name',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Child Categories',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() => addChild());
                            },
                          ),
                        ],
                      ),
                      ...childCtrls.asMap().entries.map((entry) {
                        final i = entry.key;
                        final ctrls = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: ctrls['name'],
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                TextFormField(
                                  controller: ctrls['image'],
                                  decoration: const InputDecoration(
                                    labelText: 'Image URL/Path',
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() => childCtrls.removeAt(i));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    final children = childCtrls
                        .map(
                          (ctrls) => Category(
                            name: ctrls['name']!.text.trim(),
                            image: ctrls['image']!.text.trim(),
                          ),
                        )
                        .where((c) => c.name.isNotEmpty)
                        .toList();

                    final newSup = SupCatModel(
                      name: nameCtrl.text.trim(),
                      categories: children,
                    );

                    if (isNew) {
                      final id = await provider.addSupCategory(newSup);
                      if (!mounted) return;
                      if (id != null) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Category added')),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Failed to add'),
                          ),
                        );
                      }
                    } else {
                      final ok = await provider.updateSupCategory(
                        docId!,
                        newSup,
                      );
                      if (!mounted) return;
                      if (ok) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Category updated')),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Failed to update'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isNew ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String docId,
    SupCatModel supCat,
  ) async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
          'Delete "${supCat.name}" and its ${supCat.categories.length} children?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final res = await provider.deleteSupCategory(docId);
      if (!mounted) return;
      if (res) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Delete failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: StreamBuilder<List<MapEntry<String, SupCatModel>>>(
        stream: provider.supCategoriesWithIdStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError)
            return Center(child: Text('Error: ${snap.error}'));
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No categories'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final entry = list[i];
              final docId = entry.key;
              final c = entry.value;
              return ExpansionTile(
                leading: const Icon(Icons.category),
                title: Text(c.name),
                subtitle: Text('${c.categories.length} sub-categories'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          _showSupCatForm(context, docId: docId, supCat: c),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(context, docId, c),
                      icon: const Icon(Icons.delete_forever),
                    ),
                  ],
                ),
                children: c.categories.isEmpty
                    ? [const ListTile(title: Text('No child categories'))]
                    : c.categories
                          .map(
                            (cat) => ListTile(
                              leading: cat.image.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(cat.image),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                              title: Text(cat.name),
                              subtitle: Text(cat.image),
                            ),
                          )
                          .toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupCatForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
