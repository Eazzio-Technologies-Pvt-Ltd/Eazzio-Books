class ItemModel {
  final int id;
  final String name;
  final String? sku;
  final String? hsnCode;
  final double taxRate;
  final String itemType; // Goods, Service
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

  ItemModel({
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
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      hsnCode: json['hsn_code'] as String?,
      taxRate: (json['tax_rate'] as num? ?? 0.0).toDouble(),
      itemType: json['item_type'] as String? ?? 'Goods',
      unit: json['unit'] as String?,
      sellingPrice: (json['selling_price'] as num? ?? 0.0).toDouble(),
      salesAccount: json['sales_account'] as String?,
      costPrice: (json['cost_price'] as num? ?? 0.0).toDouble(),
      purchaseAccount: json['purchase_account'] as String?,
      description: json['description'] as String?,
      purchaseDescription: json['purchase_description'] as String?,
      imageUrl: json['image_url'] as String?,
      preferredVendorId: json['preferred_vendor_id'] as int?,
      isInventoryTracked: json['is_inventory_tracked'] as bool? ?? false,
      inventoryAccount: json['inventory_account'] as String?,
      openingStock: (json['opening_stock'] as num? ?? 0.0).toDouble(),
      openingStockRate: (json['opening_stock_rate'] as num? ?? 0.0).toDouble(),
      reorderLevel: (json['reorder_level'] as num? ?? 0.0).toDouble(),
      stockQuantity: (json['stock_quantity'] as num? ?? 0.0).toDouble(),
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
    };
  }
}
