import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/banner_provider.dart';
import '../models/banner_model.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  // Controllers are created on demand inside the dialog to keep this state simple.

  Future<void> _showBannerForm(
    BuildContext context, {
    BannerModel? banner,
  }) async {
    final isNew = banner == null;
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final subtitleCtrl = TextEditingController(text: banner?.subtitle ?? '');
    final imageCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    var active = banner?.active ?? true;

    final formKey = GlobalKey<FormState>();

    final provider = Provider.of<BannerProvider>(context, listen: false);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isNew ? 'Add Banner' : 'Edit Banner'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextFormField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(labelText: 'Subtitle'),
                  ),
                  TextFormField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                    keyboardType: TextInputType.url,
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                  ),
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

                // Capture navigator/messenger before awaiting to avoid using BuildContext
                // across async gaps (fixes use_build_context_synchronously lint).
                final dialogNavigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);

                final newBanner = BannerModel(
                  id: banner?.id ?? '',
                  imageUrl: imageCtrl.text.trim(),
                  title: titleCtrl.text.trim().isEmpty
                      ? null
                      : titleCtrl.text.trim(),
                  subtitle: subtitleCtrl.text.trim().isEmpty
                      ? null
                      : subtitleCtrl.text.trim(),
                  active: active,
                );

                if (isNew) {
                  final id = await provider.addBanner(newBanner);
                  if (!mounted) return;
                  if (id != null) {
                    dialogNavigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Banner added')),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Failed to add'),
                      ),
                    );
                  }
                } else {
                  final ok = await provider.updateBanner(newBanner);
                  if (!mounted) return;
                  if (ok) {
                    dialogNavigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Banner updated')),
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
  }

  Future<void> _confirmDelete(BuildContext context, BannerModel banner) async {
    final provider = Provider.of<BannerProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete banner'),
        content: Text('Delete "${banner.title ?? banner.id}"?'),
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
      final res = await provider.deleteBanner(banner.id);
      if (!mounted) return;
      if (res) {
        messenger.showSnackBar(const SnackBar(content: Text('Banner deleted')));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Delete failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BannerProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Banners')),
      body: Stack(
        children: [
          StreamBuilder<List<BannerModel>>(
            stream: Provider.of<BannerProvider>(
              context,
              listen: false,
            ).bannersStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Center(child: Text('No banners'));
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final b = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: b.imageUrl.isNotEmpty
                          ? NetworkImage(b.imageUrl)
                          : null,
                      child: b.imageUrl.isEmpty
                          ? const Icon(Icons.photo)
                          : null,
                    ),
                    title: Text(b.title ?? 'Banner ${b.id}'),
                    subtitle: Text(b.subtitle ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (b.active)
                          const Icon(Icons.check, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.delete_forever),
                          onPressed: () => _confirmDelete(context, b),
                        ),
                      ],
                    ),
                    onTap: () => _showBannerForm(context, banner: b),
                  );
                },
              );
            },
          ),
          if (provider.loading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
