import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item_model.dart';
import '../data/repositories/item_repository.dart';

class ItemState {
  final List<ItemModel> items;
  final bool isLoading;
  final String? errorMessage;
  final bool isOperationSuccess;

  const ItemState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isOperationSuccess = false,
  });

  ItemState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool? isOperationSuccess,
  }) {
    return ItemState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isOperationSuccess: isOperationSuccess ?? this.isOperationSuccess,
    );
  }
}

class ItemNotifier extends Notifier<ItemState> {
  @override
  ItemState build() {
    Future.microtask(() => fetchItems());
    return const ItemState();
  }

  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(itemRepositoryProvider);
      final items = await repository.getItems();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addItem(Map<String, dynamic> itemData) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(itemRepositoryProvider);
      final newItem = await repository.createItem(itemData);
      state = state.copyWith(
        isLoading: false,
        items: [newItem, ...state.items],
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> editItem(int id, Map<String, dynamic> itemData) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(itemRepositoryProvider);
      final updatedItem = await repository.updateItem(id, itemData);
      state = state.copyWith(
        isLoading: false,
        items: state.items.map((item) => item.id == id ? updatedItem : item).toList(),
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> removeItem(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOperationSuccess: false);
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.deleteItem(id);
      state = state.copyWith(
        isLoading: false,
        items: state.items.where((item) => item.id != id).toList(),
        isOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final itemProvider = NotifierProvider<ItemNotifier, ItemState>(() {
  return ItemNotifier();
});
