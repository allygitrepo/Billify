import 'package:billify/data/models/product_model.dart';

/// In-memory inverted index search engine for scaling catalog searches to 50,000+ SKUs.
class CatalogSearchEngine {
  final Map<String, ProductModel> _productMap = {};
  final Map<String, Set<String>> _barcodeIndex = {};
  final Map<String, Set<String>> _tokenIndex = {};
  final Map<String, Set<String>> _categoryIndex = {};

  /// Rebuild the index with a fresh product list
  void indexProducts(List<ProductModel> products) {
    _productMap.clear();
    _barcodeIndex.clear();
    _tokenIndex.clear();
    _categoryIndex.clear();

    for (final product in products) {
      _productMap[product.id] = product;

      // Index exact & normalized barcode
      final cleanBarcode = product.barcode.trim().toLowerCase();
      if (cleanBarcode.isNotEmpty) {
        _barcodeIndex.putIfAbsent(cleanBarcode, () => {}).add(product.id);
      }

      // Index Category
      if (product.category_id != null && product.category_id!.isNotEmpty) {
        _categoryIndex.putIfAbsent(product.category_id!, () => {}).add(product.id);
      }

      // Index Words / Tokens
      final tokens = _tokenize('${product.name} ${product.barcode} ${product.uom}');
      for (final token in tokens) {
        _tokenIndex.putIfAbsent(token, () => {}).add(product.id);
      }

      // Also index variants
      for (final variant in product.variants) {
        final variantTokens = _tokenize('${variant.name} ${variant.sku}');
        for (final token in variantTokens) {
          _tokenIndex.putIfAbsent(token, () => {}).add(product.id);
        }
      }
    }
  }

  /// Fast query supporting barcode exact matching, token prefix matching, and category filter
  List<ProductModel> search({
    String? query,
    String? categoryId,
    int limit = 50,
  }) {
    final cleanQuery = query?.trim().toLowerCase() ?? '';

    // 1. Direct barcode hit (fast path)
    if (cleanQuery.isNotEmpty && _barcodeIndex.containsKey(cleanQuery)) {
      final productIds = _barcodeIndex[cleanQuery]!;
      return productIds
          .map((id) => _productMap[id])
          .whereType<ProductModel>()
          .where((p) => categoryId == null || p.category_id == categoryId)
          .take(limit)
          .toList();
    }

    Set<String>? candidateIds;

    // 2. Category filter
    if (categoryId != null && categoryId.isNotEmpty) {
      candidateIds = Set.from(_categoryIndex[categoryId] ?? {});
    }

    // 3. Tokenized text search
    if (cleanQuery.isNotEmpty) {
      final searchTokens = _tokenize(cleanQuery);
      for (final token in searchTokens) {
        final matchingProductIds = <String>{};
        for (final entry in _tokenIndex.entries) {
          if (entry.key.startsWith(token) || entry.key.contains(token)) {
            matchingProductIds.addAll(entry.value);
          }
        }

        if (candidateIds == null) {
          candidateIds = matchingProductIds;
        } else {
          candidateIds = candidateIds.intersection(matchingProductIds);
        }
      }
    }

    if (candidateIds == null) {
      // Return all (or up to limit)
      return _productMap.values.take(limit).toList();
    }

    return candidateIds
        .map((id) => _productMap[id])
        .whereType<ProductModel>()
        .take(limit)
        .toList();
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,._\-/]+'))
        .map((t) => t.trim())
        .where((t) => t.length >= 2)
        .toSet();
  }

  int get indexedCount => _productMap.length;
}
