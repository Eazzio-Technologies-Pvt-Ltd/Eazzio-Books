import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/item_model.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ItemRepository(apiClient);
});

class ItemRepository {
  final ApiClient _apiClient;

  ItemRepository(this._apiClient);

  Future<List<ItemModel>> getItems() async {
    final response = await _apiClient.get('/api/items');
    final List<dynamic> itemsData = response.data['items'] ?? [];
    return itemsData.map((json) => ItemModel.fromJson(json)).toList();
  }

  Future<ItemModel> getItemById(int id) async {
    final response = await _apiClient.get('/api/items/$id');
    final itemData = response.data['item'];
    return ItemModel.fromJson(itemData);
  }

  Future<ItemModel> createItem(Map<String, dynamic> itemData) async {
    final response = await _apiClient.post('/api/items', data: itemData);
    return ItemModel.fromJson(response.data['item']);
  }

  Future<ItemModel> updateItem(int id, Map<String, dynamic> itemData) async {
    final response = await _apiClient.put('/api/items/$id', data: itemData);
    return ItemModel.fromJson(response.data['item']);
  }

  Future<void> deleteItem(int id) async {
    await _apiClient.delete('/api/items/$id');
  }
}
