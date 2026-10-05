import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/admin_product.dart';
import '../../../../domain/entities/product_category.dart';
import '../../../../domain/repositories/product_admin_repository.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/price_field.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final _repository = sl<ProductAdminRepository>();
  final _newCategoryController = TextEditingController();

  final _newProductFormKey = GlobalKey<FormState>();
  final _newProductNameController = TextEditingController();
  final _newProductPriceController = TextEditingController();
  int? _newProductCategoryId;
  bool _newProductActive = true;
  bool _isCreatingProduct = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<ProductCategory> _categories = [];
  List<AdminProduct> _products = [];
  int? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _newProductNameController.dispose();
    _newProductPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final categoriesResult = await _repository.listCategories(includeInactive: false);
    final productsResult = await _repository.listProducts(includeInactive: true);

    if (!mounted) return;

    String? error;
    List<ProductCategory> categories = [];
    List<AdminProduct> products = [];

    categoriesResult.when(
      left: (DomainError failure) => error = failure.message,
      right: (List<ProductCategory> value) => categories = value,
    );
    productsResult.when(
      left: (DomainError failure) => error ??= failure.message,
      right: (List<AdminProduct> value) => products = value,
    );

    setState(() {
      _categories = categories;
      _products = products;
      _isLoading = false;
      _errorMessage = error;
    });
  }

  String _categoryName(int? categoryId) {
    if (categoryId == null) return 'Sin categoría';
    final match = _categories.where((c) => c.categoryId == categoryId);
    return match.isEmpty ? 'Sin categoría' : match.first.name;
  }

  List<AdminProduct> get _visibleProducts {
    if (_selectedCategoryFilter == null) return _products;
    return _products.where((p) => p.categoryId == _selectedCategoryFilter).toList();
  }

  Future<void> _createProduct() async {
    if (!(_newProductFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isCreatingProduct = true);

    final result = await _repository.createProduct(
      name: _newProductNameController.text.trim(),
      price: ThousandsFormat.parsePrice(_newProductPriceController.text.trim()) ?? 0,
      categoryId: _newProductCategoryId,
    );

    if (!mounted) return;

    result.when(
      left: (DomainError failure) {
        setState(() => _isCreatingProduct = false);
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
      },
      right: (AdminProduct created) {
        setState(() {
          _isCreatingProduct = false;
          _products = [..._products, created];
          _newProductNameController.clear();
          _newProductPriceController.clear();
        });
      },
    );
  }

  Future<void> _renameProduct(AdminProduct product) async {
    final controller = TextEditingController(text: product.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar producto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final result = await _repository.updateProduct(product.productId, name: name);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (AdminProduct updated) => setState(() {
        _products = _products.map((p) => p.productId == updated.productId ? updated : p).toList();
      }),
    );
  }

  Future<void> _toggleProductActive(AdminProduct product) async {
    final result = await _repository.setProductActive(product.productId, !product.active);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (AdminProduct updated) => setState(() {
        _products = _products.map((p) => p.productId == updated.productId ? updated : p).toList();
      }),
    );
  }

  Future<void> _createCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    final result = await _repository.createCategory(name);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (ProductCategory category) {
        setState(() => _categories = [..._categories, category]);
        _newCategoryController.clear();
      },
    );
  }

  Future<void> _renameCategory(ProductCategory category) async {
    final controller = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renombrar categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final result = await _repository.renameCategory(category.categoryId, name);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (ProductCategory updated) => setState(() {
        _categories = _categories.map((c) => c.categoryId == updated.categoryId ? updated : c).toList();
      }),
    );
  }

  Future<void> _toggleCategoryActive(ProductCategory category) async {
    final result = await _repository.setCategoryActive(category.categoryId, !category.active);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (ProductCategory updated) => setState(() {
        // Se cargan solo categorías activas (includeInactive: false), así que
        // desactivar una la saca de la lista visible.
        _categories = _categories.where((c) => c.categoryId != updated.categoryId).toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _products.isEmpty && _categories.isEmpty) {
      return Center(child: Text(_errorMessage!));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo de productos y extras que se pueden vender dentro de una sesión (bebidas, alquiler de paletas, etc.).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _selectedCategoryFilter == null,
                        onSelected: (_) => setState(() => _selectedCategoryFilter = null),
                      ),
                      ..._categories.map((category) => ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedCategoryFilter == category.categoryId,
                            onSelected: (_) => setState(() => _selectedCategoryFilter = category.categoryId),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_visibleProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Todavía no hay productos.'),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AdminDataTable(
                        columns: const ['Nombre', 'Categoría', 'Precio', 'Activo', ''],
                        rows: _visibleProducts
                            .map((product) => [
                                  Text(product.name),
                                  Chip(
                                    label: Text(_categoryName(product.categoryId)),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Text('\$${ThousandsFormat.formatPrice(product.price)}'),
                                  Switch(
                                    value: product.active,
                                    onChanged: (_) => _toggleProductActive(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _renameProduct(product),
                                  ),
                                ])
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildInlineProductForm(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Categorías', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Las categorías se administran por separado y se usan para filtrar el catálogo.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories
                        .map((category) => Container(
                              padding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                border: Border.all(color: colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(category.name),
                                  const SizedBox(width: 6),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: category.active,
                                      onChanged: (_) => _toggleCategoryActive(category),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => _renameCategory(category),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _newCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Nueva categoría',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: _createCategory, child: const Text('Crear categoría')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineProductForm() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Form(
        key: _newProductFormKey,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 220,
              child: TextFormField(
                controller: _newProductNameController,
                decoration: const InputDecoration(labelText: 'Nombre', isDense: true, border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _newProductCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría', isDense: true, border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
                  ..._categories.map((c) => DropdownMenuItem<int?>(value: c.categoryId, child: Text(c.name))),
                ],
                onChanged: (value) => setState(() => _newProductCategoryId = value),
              ),
            ),
            SizedBox(
              width: 120,
              child: PriceField(
                controller: _newProductPriceController,
                decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                isDense: true,
                validator: (v) {
                  final parsed = ThousandsFormat.parsePrice((v ?? '').trim());
                  return (parsed == null || parsed < 0) ? 'Inválido' : null;
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Activo', style: Theme.of(context).textTheme.bodySmall),
                Switch(value: _newProductActive, onChanged: (v) => setState(() => _newProductActive = v)),
              ],
            ),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: _isCreatingProduct ? null : _createProduct,
                child: _isCreatingProduct
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Agregar producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
