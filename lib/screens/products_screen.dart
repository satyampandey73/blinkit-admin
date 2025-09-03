import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Future<void> _showProductForm(
    BuildContext context, {
    ProductModel? product,
  }) async {
    final isNew = product == null;
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // fetch sup categories once before showing dialog so we can populate dropdowns
    final supCats = await categoryProvider.fetchAllSupCategories();

    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product?.price.toString() ?? '0',
    );
    final qtyCtrl = TextEditingController(text: product?.quantity ?? '0');
    final discountCtrl = TextEditingController(
      text: product?.discountPercent.toString() ?? '0',
    );
    final superCatCtrl = TextEditingController(
      text: product?.superCategory ?? '',
    );
    final subCatCtrl = TextEditingController(text: product?.subCategory ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final detailCtrl = TextEditingController(
      text: product?.productDetail ?? '',
    );
    final returnCtrl = TextEditingController(text: product?.returnPolicy ?? '');

    // list of image controllers
    final imageCtrls = <TextEditingController>[];
    if (product != null && product.images.isNotEmpty) {
      for (var img in product.images) {
        imageCtrls.add(TextEditingController(text: img));
      }
    } else {
      imageCtrls.add(TextEditingController());
    }

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            String selectedSuper = superCatCtrl.text.isNotEmpty
                ? superCatCtrl.text
                : ('');
            List<Category> currentSubCats = [];
            try {
              final sup = supCats.firstWhere((s) => s.name == selectedSuper);
              currentSubCats = sup.categories;
            } catch (_) {
              currentSubCats = [];
            }
            String selectedSub = subCatCtrl.text;
            void addImageField() =>
                setState(() => imageCtrls.add(TextEditingController()));
            void removeImageField(int i) =>
                setState(() => imageCtrls.removeAt(i));

            return AlertDialog(
              title: Text(isNew ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                            ? 'Enter valid price'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: discountCtrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Super category dropdown
                      DropdownButtonFormField<String>(
                        value: selectedSuper.isNotEmpty ? selectedSuper : null,
                        decoration: const InputDecoration(
                          labelText: 'Super Category',
                        ),
                        items: supCats
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.name,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSuper = val ?? '';
                            superCatCtrl.text = selectedSuper;
                            // update available subcategories
                            try {
                              final sup = supCats.firstWhere(
                                (s) => s.name == selectedSuper,
                              );
                              currentSubCats = sup.categories;
                            } catch (_) {
                              currentSubCats = [];
                            }
                            // reset selected sub
                            selectedSub = '';
                            subCatCtrl.text = '';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Sub category dropdown (depends on selected super category)
                      DropdownButtonFormField<String>(
                        value: selectedSub.isNotEmpty ? selectedSub : null,
                        decoration: const InputDecoration(
                          labelText: 'Sub Category',
                        ),
                        items: currentSubCats
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSub = val ?? '';
                            subCatCtrl.text = selectedSub;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: detailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Detail',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: returnCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Return Policy',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Images',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: addImageField,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      ...imageCtrls.asMap().entries.map((e) {
                        final i = e.key;
                        final ctrl = e.value;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ctrl,
                                decoration: InputDecoration(
                                  labelText: 'Image URL ${i + 1}',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: imageCtrls.length == 1
                                  ? null
                                  : () => removeImageField(i),
                            ),
                          ],
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

                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    final qty = qtyCtrl.text.trim();
                    final discount = double.tryParse(discountCtrl.text) ?? 0.0;
                    final images = imageCtrls
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final prod = ProductModel(
                      id: product?.id,
                      name: name,
                      images: images,
                      quantity: qty,
                      price: price,
                      discountPercent: discount,
                      superCategory: superCatCtrl.text.trim().isEmpty
                          ? null
                          : superCatCtrl.text.trim(),
                      subCategory: subCatCtrl.text.trim().isEmpty
                          ? null
                          : subCatCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      productDetail: detailCtrl.text.trim().isEmpty
                          ? null
                          : detailCtrl.text.trim(),
                      returnPolicy: returnCtrl.text.trim().isEmpty
                          ? null
                          : returnCtrl.text.trim(),
                    );

                    if (isNew) {
                      final id = await provider.addProduct(prod);
                      if (!mounted) return;
                      if (id != null) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Product added')),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Failed to add'),
                          ),
                        );
                      }
                    } else {
                      final ok = await provider.updateProduct(prod);
                      if (!mounted) return;
                      if (ok) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Product updated')),
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

  Future<void> _confirmDelete(BuildContext context, ProductModel p) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${p.name}"?'),
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
      final id = p.id;
      if (id == null || id.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Product id not available')),
        );
        return;
      }
      final res = await provider.deleteProduct(id);
      if (!mounted) return;
      if (res) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Product deleted')),
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
    final provider = Provider.of<ProductProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: StreamBuilder<List<ProductModel>>(
        stream: provider.productsStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No products'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final p = list[i];
              return ListTile(
                leading: p.images.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(p.images.first),
                      )
                    : const CircleAvatar(child: Icon(Icons.shopping_bag)),
                title: Text(p.name),
                subtitle: Text(
                  'Price: ₹${p.price.toStringAsFixed(2)} • Qty: ${p.quantity}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showProductForm(context, product: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () => _confirmDelete(context, p),
                    ),
                  ],
                ),
                onTap: () => _showProductForm(context, product: p),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
