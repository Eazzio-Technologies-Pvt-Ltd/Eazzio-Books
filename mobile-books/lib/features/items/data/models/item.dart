class Item {
  final int id;
  final String name;
  final String? sku;
  final String? hsnCode;
  final double taxRate;
  final String itemType; // 'Goods' or 'Service'
  final String? unit;
  final double sellingPrice;
  final String? salesAccount;
  final double costPrice;
  final String? purchaseAccount;
  final String? description;
  final String? purchaseDescription;
  final String? imageUrl;
  final int? preferredVendorId;
  final bool isInventoryTracked;
  final String? inventoryAccount;
  final double openingStock;
  final double openingStockRate;
  final double reorderLevel;
  final double stockQuantity;
  final int organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    required this.id,
    required this.name,
    this.sku,
    this.hsnCode,
    required this.taxRate,
    required this.itemType,
    this.unit,
    required this.sellingPrice,
    this.salesAccount,
    required this.costPrice,
    this.purchaseAccount,
    this.description,
    this.purchaseDescription,
    this.imageUrl,
    this.preferredVendorId,
    required this.isInventoryTracked,
    this.inventoryAccount,
    required this.openingStock,
    required this.openingStockRate,
    required this.reorderLevel,
    required this.stockQuantity,
    required this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      hsnCode: json['hsn_code'] as String?,
      taxRate: _parseDouble(json['tax_rate']),
      itemType: json['item_type'] as String? ?? 'Goods',
      unit: json['unit'] as String?,
      sellingPrice: _parseDouble(json['selling_price']),
      salesAccount: json['sales_account'] as String?,
      costPrice: _parseDouble(json['cost_price']),
      purchaseAccount: json['purchase_account'] as String?,
      description: json['description'] as String?,
      purchaseDescription: json['purchase_description'] as String?,
      imageUrl: json['image_url'] as String?,
      preferredVendorId: json['preferred_vendor_id'] as int?,
      isInventoryTracked: json['is_inventory_tracked'] as bool? ?? false,
      inventoryAccount: json['inventory_account'] as String?,
      openingStock: _parseDouble(json['opening_stock']),
      openingStockRate: _parseDouble(json['opening_stock_rate']),
      reorderLevel: _parseDouble(json['reorder_level']),
      stockQuantity: _parseDouble(json['stock_quantity']),
      organizationId: json['organization_id'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'hsn_code': hsnCode,
      'tax_rate': taxRate,
      'item_type': itemType,
      'unit': unit,
      'selling_price': sellingPrice,
      'sales_account': salesAccount,
      'cost_price': costPrice,
      'purchase_account': purchaseAccount,
      'description': description,
      'purchase_description': purchaseDescription,
      'image_url': imageUrl,
      'preferred_vendor_id': preferredVendorId,
      'is_inventory_tracked': isInventoryTracked,
      'inventory_account': inventoryAccount,
      'opening_stock': openingStock,
      'opening_stock_rate': openingStockRate,
      'reorder_level': reorderLevel,
      'stock_quantity': stockQuantity,
      'organization_id': organizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? sku,
    String? hsnCode,
    double? taxRate,
    String? itemType,
    String? unit,
    double? sellingPrice,
    String? salesAccount,
    double? costPrice,
    String? purchaseAccount,
    String? description,
    String? purchaseDescription,
    String? imageUrl,
    int? preferredVendorId,
    bool? isInventoryTracked,
    String? inventoryAccount,
    double? openingStock,
    double? openingStockRate,
    double? reorderLevel,
    double? stockQuantity,
    int? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
      itemType: itemType ?? this.itemType,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      salesAccount: salesAccount ?? this.salesAccount,
      costPrice: costPrice ?? this.costPrice,
      purchaseAccount: purchaseAccount ?? this.purchaseAccount,
      description: description ?? this.description,
      purchaseDescription: purchaseDescription ?? this.purchaseDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      preferredVendorId: preferredVendorId ?? this.preferredVendorId,
      isInventoryTracked: isInventoryTracked ?? this.isInventoryTracked,
      inventoryAccount: inventoryAccount ?? this.inventoryAccount,
      openingStock: openingStock ?? this.openingStock,
      openingStockRate: openingStockRate ?? this.openingStockRate,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
