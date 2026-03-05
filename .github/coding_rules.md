# CODING_RULES.md

## 1. Naming Conventions

### 1.1 Files

```
✅ stock_item.dart           # Entity
✅ stock_repository.dart     # Abstract repo
✅ stock_repository_impl.dart # Concrete repo
✅ stock_provider.dart       # Provider
✅ stock_screen.dart         # Screen
✅ stock_item_tile.dart      # Widget
✅ stock_item_mapper.dart    # Mapper
✅ stock_items_table.dart    # Drift table
✅ auth_exceptions.dart      # Exceptions

❌ StockItem.dart            # NO PascalCase
❌ stock_item_widget.dart    # Use specific name (stock_item_tile.dart)
❌ utils.dart                # NO generic names
❌ helpers.dart              # NO generic names
❌ models.dart               # NO plural generic (use entity_model.dart)
```

**Rules:**
- snake_case only
- Pattern: `[domain]_[type].dart`
- Be specific (no `utils.dart`, `helpers.dart`, `models.dart`)
- File name = main class name (lowercase + snake_case)

---

### 1.2 Classes

```dart
✅ class StockItem { }           # Entity
✅ class StockRepository { }     # Interface
✅ class StockRepositoryImpl { }  # Implementation
✅ class StockItemMapper { }     # Mapper
✅ class StockNotifier extends StateNotifier { } # Notifier
✅ class StockScreen extends ConsumerWidget { }  # Screen
✅ class StockItemTile extends StatelessWidget { } # Widget

❌ class stock_item { }          # NO snake_case
❌ class StockItemWidget { }     # NO generic "Widget" suffix
❌ class Util { }                # NO generic class names
```

**Rules:**
- PascalCase only
- Suffix `Impl` for concrete implementations (not `_concrete`)
- No "Widget" suffix (redundant, use specific name: `StockItemTile`)
- Extend correct base: `ConsumerWidget`, `StatelessWidget`, `StatefulWidget`

---

### 1.3 Variables & Constants

```dart
// Variables
✅ final stockItems = [...];
✅ late final database = AppDatabase();
✅ var count = 0;

❌ final StockItems = [...];     # NO PascalCase
❌ final _stockItems = [...];    # NO underscore for non-private

// Constants
✅ const defaultPageSize = 20;
✅ const String apiBaseUrl = 'https://api.example.com';

❌ const DEFAULT_PAGE_SIZE = 20; # NO SCREAMING_SNAKE_CASE
❌ const DefaultPageSize = 20;   # NO PascalCase

// Parameters
✅ Future<void> addStockItem({
  required String name,
  required int quantity,
  String? reason,
})

❌ Future<void> addStockItem(
  String name,    # NO positional (always named)
  int quantity,
)
```

**Rules:**
- Variables/parameters: camelCase
- Constants: camelCase (same as variables)
- NO SCREAMING_SNAKE_CASE (deprecated Dart style)
- ALL parameters: named + required/optional explicit
- NO positional parameters in public APIs

---

### 1.4 Private vs Public

```dart
✅ class StockItem {
  final String _id;           // Private field (underscore)
  late final _database = ...;
  
  String get id => _id;       // Public getter (no underscore)
  
  void _initializeData() { }  // Private method (underscore)
  void initialize() { }       // Public method (no underscore)
}

❌ final stockItem;           # NO private without underscore
❌ final _stockItem;          # Private exported (should be public or encapsulated)
❌ String get _id => _id;     # NO getter underscore
```

**Rules:**
- Private fields: `_fieldName` (underscore prefix)
- Private methods: `_methodName` (underscore prefix)
- Public getters: `fieldName` (no underscore)
- NO protected (Dart doesn't have it)

---

### 1.5 Enums & Types

```dart
✅ enum Role { admin, manager, user }
✅ enum StockMovementType { in, out, adjustment, return }
✅ enum SyncStatus { pending, inProgress, failed, success }

❌ enum Role { ADMIN, MANAGER, USER }           # NO SCREAMING_SNAKE_CASE
❌ enum role { admin, manager, user }           # NO lowercase class
❌ enum StockMovementType { In, Out }           # NO PascalCase values
```

**Rules:**
- Enum class: PascalCase
- Enum values: lowercase
- Enum filename: `role.dart` (lowercase, NOT enum_role.dart)

---

## 2. Widget Structure

### 2.1 StatelessWidget

```dart
class StockItemTile extends StatelessWidget {
  const StockItemTile({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  final StockItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: Text('${item.quantity} units'),
        ),
      ),
    );
  }
}
```

**Rules:**
- `const` constructor required
- ALL parameters: `final`
- `Key? key` first parameter
- `super(key: key)` required
- build() returns single widget
- NO internal state

---

### 2.2 ConsumerWidget

```dart
class StockListScreen extends ConsumerWidget {
  const StockListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockProvider);

    return stockAsync.when(
      data: (items) => StockList(items),
      loading: () => LoadingIndicator(),
      error: (error, st) => ErrorBanner(error: error.toString()),
    );
  }
}
```

**Rules:**
- Use for provider access only
- `build()` receives `WidgetRef ref`
- ALWAYS use `.when()` for AsyncValue
- NO business logic (use providers)

---

### 2.3 StatefulWidget (Rare)

```dart
class FormScreen extends StatefulWidget {
  const FormScreen({Key? key}) : super(key: key);

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _nameController);
  }
}
```

**Rules:**
- ONLY for local UI state (forms, animations)
- State class: `_WidgetNameState` (private)
- ALWAYS dispose controllers/listeners
- NO business logic (delegate to providers)

---

### 2.4 Widget Build Best Practices

```dart
// ✅ DO
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Stock')),
    body: ListView(
      children: items.map(StockItemTile.new).toList(),
    ),
  );
}

// ❌ DON'T
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Stock')),
    body: ListView(
      children: [
        for (final item in items)
          StockItemTile(item: item),
      ],
    ),
  );
}

// ❌ DON'T - Extract widget
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Title'),
          SizedBox(height: 16),
          for (final item in items)
            GestureDetector(
              onTap: () { /* handler */ },
              child: Container(...),
            ),
        ],
      ),
    ),
  );
}
```

**Rules:**
- Use `.map().toList()` for lists
- Extract complex widgets to separate classes
- Max nesting: 3 levels (Scaffold → body container → child)
- Limit build() to 50 lines

---

## 3. File Size Limits

```
Entity file:         < 200 lines
Provider file:       < 300 lines
Screen file:         < 500 lines
Widget file:         < 300 lines
Repository impl:     < 400 lines
Service file:        < 400 lines

Widget with 500+ lines = SPLIT INTO MULTIPLE WIDGETS
```

**Rules:**
- File > 300 lines: Extract helper widgets/functions
- File > 500 lines: Separate into multiple files
- 1 primary widget per file (helper widgets after)
- Use private widgets `_HeaderWidget` if needed

---

## 4. Comments

### 4.1 When to Comment

```dart
✅ // Retry logic: exponential backoff 2^n seconds
Future<void> retryWithBackoff(int attempt) {
  final delaySeconds = pow(2, attempt).toInt();
  // ...
}

✅ /// Custom exception for rate limiting.
/// 
/// Used when user exceeds 10 login attempts per 15 minutes.
class RateLimitException implements Exception {
  // ...
}

✅ // TODO: Implement pull from Firestore for multi-device sync
// Currently only pushing to Firestore

❌ // Increment count
count++;

❌ // This is a widget
class MyWidget extends StatelessWidget { }

❌ // Get stock items
Future<List<StockItem>> getStockItems() { }
```

**Rules:**
- Comment: WHY (not WHAT)
- WHY is non-obvious logic (exponential backoff, edge cases)
- WHY is complex decision (why use last-write-wins, not CRDTs)
- NO comment for obvious code
- NO comment for method names (name explains it)
- TODO: Include context + reason
- Doc comments: Public APIs only (///)

---

### 4.2 Doc Comments

```dart
/// Adds a stock item to inventory.
///
/// Returns the new item ID.
///
/// Throws [InvalidQuantityException] if quantity <= 0.
/// Throws [DuplicateNameException] if name already exists.
Future<int> addStockItem({
  required String name,
  required int quantity,
  required String category,
}) async {
  // ...
}

/// Syncs stock to Firestore.
///
/// Batches operations (max 500) per Firestore transaction limits.
/// Retries on failure with exponential backoff.
///
/// See: [SyncQueue], [FirebaseSyncService]
Future<void> syncStock() async {
  // ...
}
```

**Rules:**
- Public methods: /// doc comment required
- Private methods: NO doc comment (use // if needed)
- Public classes: /// doc comment required
- Include: What, Returns, Throws, Links
- Link related: `[ClassName]`, `[methodName]`

---

## 5. Async / Await Rules

### 5.1 Async Functions

```dart
✅ Future<void> loadStockItems() async {
  final items = await _repository.getAllStockItems();
  _items = items;
}

✅ Future<List<StockItem>> getAllStockItems() async {
  try {
    return await _db.watchAllStockItems().first;
  } catch (e) {
    rethrow;
  }
}

✅ final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  return await ref.watch(stockRepositoryProvider).getAllStockItems();
});

❌ Future<void> loadStockItems() {
  return _repository.getAllStockItems().then((items) {
    _items = items;
  });
}

❌ Future<List<StockItem>> getAllStockItems() {
  return _db.watchAllStockItems().first;
}

❌ final stockProvider = FutureProvider<List<StockItem>>((ref) {
  return ref.watch(stockRepositoryProvider).getAllStockItems();
});
```

**Rules:**
- ALWAYS use async/await (NOT `.then()`)
- ALWAYS mark function with `async` if it uses `await`
- ALWAYS return `Future<T>` for async functions
- Provider can omit `async` if single expression returns Future

---

### 5.2 Error Handling

```dart
✅ Future<void> syncStock() async {
  try {
    await _firebaseService.sync();
  } catch (e, st) {
    debugPrint('❌ Sync failed: $e');
    rethrow;
  }
}

✅ final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  try {
    final repo = ref.watch(stockRepositoryProvider);
    return await repo.getAllStockItems();
  } catch (e, st) {
    debugPrint('❌ Error: $e');
    rethrow;
  }
});

❌ Future<void> syncStock() async {
  await _firebaseService.sync();
}

❌ Future<void> syncStock() async {
  try {
    await _firebaseService.sync();
  } catch (e) {
    // Swallow exception silently
  }
}

❌ Future<void> syncStock() async {
  try {
    await _firebaseService.sync();
  } catch (e) {
    return; // Don't rethrow
  }
}
```

**Rules:**
- ALL async functions wrapped in try/catch
- Catch (e, st) - always capture stacktrace
- Log error with debugPrint()
- Rethrow unless handled
- NEVER swallow exceptions silently
- NEVER return instead of rethrow

---

### 5.3 Timeouts

```dart
✅ Future<List<StockItem>> getAllStockItems() async {
  return _db.watchAllStockItems()
    .first
    .timeout(Duration(seconds: 10));
}

✅ Future<void> syncStock() async {
  try {
    await _firebaseService.sync()
      .timeout(Duration(seconds: 30));
  } on TimeoutException {
    throw SyncTimeoutException('Sync took too long');
  }
}

❌ Future<List<StockItem>> getAllStockItems() async {
  return _db.watchAllStockItems().first;
}
```

**Rules:**
- Network operations: Add timeout (30 sec)
- Database operations: Add timeout (10 sec)
- Throw specific exception on timeout (not TimeoutException)

---

## 6. Models & DTOs

### 6.1 Entity (Domain)

```dart
@immutable
class StockItem {
  const StockItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int quantity;
  final int minThreshold;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockItem copyWith({
    int? id,
    String? name,
    int? quantity,
    int? minThreshold,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is StockItem &&
      runtimeType == other.runtimeType &&
      id == other.id &&
      name == other.name &&
      quantity == other.quantity &&
      minThreshold == other.minThreshold &&
      category == other.category &&
      createdAt == other.createdAt &&
      updatedAt == other.updatedAt;

  @override
  int get hashCode =>
    id.hashCode ^
    name.hashCode ^
    quantity.hashCode ^
    minThreshold.hashCode ^
    category.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;

  @override
  String toString() =>
    'StockItem(id: $id, name: $name, quantity: $quantity, '
    'minThreshold: $minThreshold, category: $category, '
    'createdAt: $createdAt, updatedAt: $updatedAt)';
}
```

**Rules:**
- @immutable required
- All fields final
- Nullable id (for pre-insert)
- ALL fields in copyWith()
- ALL fields in ==, hashCode, toString()
- Use Freezed if > 10 fields

---

### 6.2 Model (Data Layer)

```dart
// Drift Table Model
class StockItemsTableCompanion extends Insertable<StockItemsTableCompanion> {
  final Value<int?> id;
  final Value<String> name;
  final Value<int> quantity;
  final Value<int> minThreshold;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;

  const StockItemsTableCompanion({
    this.id = const Value.absent(),
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
}

// Local DTO (if needed)
class StockItemLocalModel {
  const StockItemLocalModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int quantity;
  final int minThreshold;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StockItemLocalModel.fromJson(Map<String, dynamic> json) {
    return StockItemLocalModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      minThreshold: json['minThreshold'] as int,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

**Rules:**
- Drift models: Auto-generated, use Value<T> wrapper
- Local DTOs: toJson() + fromJson() required
- NO business logic in models
- Use Freezed for JSON serialization if complex

---

### 6.3 Mapper

```dart
class StockItemMapper {
  static StockItem toDomain(StockItemLocalModel model) {
    return StockItem(
      id: model.id,
      name: model.name,
      quantity: model.quantity,
      minThreshold: model.minThreshold,
      category: model.category,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static StockItemLocalModel toLocal(StockItem entity) {
    return StockItemLocalModel(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      minThreshold: entity.minThreshold,
      category: entity.category,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static StockItem fromJson(Map<String, dynamic> json) {
    return toDomain(StockItemLocalModel.fromJson(json));
  }

  static Map<String, dynamic> toJson(StockItem entity) {
    return toLocal(entity).toJson();
  }
}
```

**Rules:**
- Static methods only
- `toDomain()` - Model → Entity
- `toLocal()` - Entity → Model
- `fromJson()` - JSON → Entity
- `toJson()` - Entity → JSON
- ONE mapper per entity

---

## 7. Tests

### 7.1 Unit Tests - When Required

```
❌ Obvious code: NO test
❌ Getter/setter: NO test
❌ Generated code (Drift, Freezed): NO test

✅ Business logic: TEST
✅ Validators: TEST
✅ Mappers: TEST
✅ Repository queries: TEST
✅ Providers (logic): TEST
```

**Rules:**
- Test domain logic only (entities, validators, permission resolver)
- Test repository methods (error cases, edge cases)
- Test providers (state changes, invalidation)
- NO tests for obvious UI code

---

### 7.2 Unit Test Pattern

```dart
void main() {
  group('StockItem', () {
    test('isLowOnStock returns true when quantity <= minThreshold', () {
      // Arrange
      final item = StockItem(
        quantity: 5,
        minThreshold: 10,
        // ...
      );

      // Act
      final result = item.isLowOnStock;

      // Assert
      expect(result, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      final original = StockItem(name: 'Old', quantity: 10, ...);
      final updated = original.copyWith(name: 'New');

      expect(updated.name, equals('New'));
      expect(updated.quantity, equals(10));
    });
  });

  group('StockItemMapper', () {
    test('toDomain converts model to entity correctly', () {
      final model = StockItemLocalModel(...);
      final entity = StockItemMapper.toDomain(model);

      expect(entity.id, equals(model.id));
      expect(entity.name, equals(model.name));
    });
  });
}
```

**Rules:**
- 1 test per behavior (not per method)
- Arrange → Act → Assert pattern
- Test name describes behavior (not method name)
- Mock external dependencies
- ONE assertion per test (when possible)

---

### 7.3 Widget Tests - Critical Screens Only

```dart
testWidgets('StockScreen shows loading indicator while loading', (tester) async {
  // Arrange
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stockProvider.overrideWithValue(
          AsyncValue.loading(),
        ),
      ],
      child: MaterialApp(home: StockScreen()),
    ),
  );

  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('StockScreen shows error widget on failure', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stockProvider.overrideWithValue(
          AsyncValue.error(Exception('Error'), StackTrace.current),
        ),
      ],
      child: MaterialApp(home: StockScreen()),
    ),
  );

  expect(find.byType(ErrorWidget), findsOneWidget);
});
```

**Rules:**
- ONLY critical screens (login, home, admin)
- ONLY state changes (loading, error, data)
- NO UI pixel testing
- Mock providers with override
- Test 3 states: loading, error, success

---

## 8. Forbidden Patterns (Anti-Patterns)

### 8.1 ❌ NEVER DO

```dart
// ❌ NO print() - use debugPrint()
print('Debug: $value');

// ✅ DO
debugPrint('Debug: $value');
```

```dart
// ❌ NO .then() chains - use async/await
future.then((result) => next(result)).catchError((e) => handle(e));

// ✅ DO
try {
  final result = await future;
  next(result);
} catch (e) {
  handle(e);
}
```

```dart
// ❌ NO positional parameters
void addItem(String name, int qty, String category) { }

// ✅ DO
void addItem({
  required String name,
  required int qty,
  required String category,
}) { }
```

```dart
// ❌ NO generic names
class Utils { }
class Helpers { }
class Models { }

// ✅ DO
class DateFormatter { }
class PermissionValidator { }
class StockItemLocalModel { }
```

```dart
// ❌ NO business logic in widgets
class StockListScreen extends StatelessWidget {
  @override
  Widget build(context) {
    // WRONG: logic here
    final filtered = items.where((i) => i.quantity < i.minThreshold).toList();
    return ListView(children: filtered.map(...).toList());
  }
}

// ✅ DO
class StockListScreen extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final filtered = ref.watch(lowStockItemsProvider); // Provider handles logic
    return filtered.when(
      data: (items) => StockList(items),
      loading: () => LoadingIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

```dart
// ❌ NO God Providers (watching everything)
final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  final stock = await ref.watch(stockProvider.future);
  final terrain = await ref.watch(terrainProvider.future);
  final maintenance = await ref.watch(maintenanceProvider.future);
  final events = await ref.watch(eventProvider.future);
  final weather = await ref.watch(weatherProvider.future);
  // Combine everything...
});

// ✅ DO - Use individual providers + computed providers
final dashboardStockProvider = FutureProvider<DashboardStock>((ref) async {
  return ref.watch(stockProvider);
});
```

```dart
// ❌ NO setState() in ConsumerWidget
class MyScreen extends ConsumerWidget {
  // setState() doesn't exist - use StateNotifierProvider instead
}

// ✅ DO
final myStateProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => MyNotifier());

class MyScreen extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final state = ref.watch(myStateProvider);
    return Text(state.value);
  }
}
```

```dart
// ❌ NO nullable returns when empty
Future<List<StockItem>> getAllItems() async {
  final items = await repo.getAll();
  return items.isEmpty ? null : items; // WRONG
}

// ✅ DO
Future<List<StockItem>> getAllItems() async {
  return await repo.getAll(); // Return empty list
}
```

```dart
// ❌ NO try/catch in UI
class StockList extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    try {
      final items = ref.watch(stockProvider); // Wrong place for try/catch
    } catch (e) {
      // error handling
    }
  }
}

// ✅ DO - Handle in provider, show in UI
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  try {
    return await repo.getAll();
  } catch (e) {
    rethrow; // Let AsyncValue.error handle it
  }
});

class StockList extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    return ref.watch(stockProvider).when(
      data: (items) => ListView(...),
      error: (e, st) => ErrorWidget(e), // Error handling here
      loading: () => LoadingIndicator(),
    );
  }
}
```

```dart
// ❌ NO mutable entities
var item = StockItem(...);
item.quantity = 10; // WRONG - entity is mutable

// ✅ DO
final item = StockItem(...);
final updated = item.copyWith(quantity: 10); // Immutable
```

```dart
// ❌ NO circular dependencies
// domain imports data
// data imports presentation
// presentation imports domain (cycles)

// ✅ DO - Unidirectional
// presentation watches providers
// providers inject repositories
// repositories implement domain interfaces
// domain has zero imports of data/presentation
```

```dart
// ❌ NO Future<void> mutations without sync
Future<void> addStockItem(StockItem item) async {
  await _db.insertStockItem(item);
  // Missing: SyncQueue entry
  // Missing: ref.invalidate(stockProvider)
}

// ✅ DO
Future<void> addStockItem(StockItem item) async {
  await _db.insertStockItem(item);
  await _db.insertSyncQueue(operation: 'CREATE', entity: 'stock', entityId: item.id);
  // In provider: ref.invalidate(stockProvider);
}
```

```dart
// ❌ NO magic numbers
final delay = Future.delayed(Duration(seconds: 30));

// ✅ DO
const syncTimeoutSeconds = 30;
final delay = Future.delayed(Duration(seconds: syncTimeoutSeconds));
```

```dart
// ❌ NO catching generic Exception
try {
  await operation();
} catch (e) {
  // Too broad
}

// ✅ DO
try {
  await operation();
} catch (e, st) {
  debugPrint('Error: $e');
  rethrow;
}
```

---

### 8.2 Forbidden Imports

```dart
❌ import 'package:flutter/foundation.dart';  // In domain/
❌ import 'package:drift/drift.dart';         // In domain/
❌ import 'package:cloud_firestore/cloud_firestore.dart'; // In domain/
❌ import 'package:flutter_riverpod/flutter_riverpod.dart'; // In domain/

❌ import 'presentation/'; // In data/
❌ import '../presentation/'; // In data/

❌ import 'package:flutter_riverpod/'; // In data/
❌ import 'package:flutter/'; // In domain/

✅ import 'package:flutter/'; // In presentation/
✅ import 'package:flutter_riverpod/'; // In presentation/
✅ import '../domain/'; // In data/
✅ import '../domain/'; // In presentation/
```

---

### 8.3 Forbidden Patterns

```dart
❌ Getter side effects
String get userId {
  print('Getting user ID'); // NO side effects
  return _userId;
}

❌ Widget rebuilding on every frame
AnimationBuilder(builder: () => expensiveWidget()) // NO

❌ Multiple StateNotifiers for one feature
final counterNotifier = StateNotifierProvider(...);
final counterNotifier2 = StateNotifierProvider(...);

❌ @override toString() in release builds
@override
String toString() => 'Complex representation'; // NO - affects perf
```

---

## 9. Code Organization Patterns

### 9.1 Provider Organization

```dart
// File: lib/features/inventory/providers/stock_provider.dart

// 1. Repository injection
final stockRepositoryProvider = Provider((ref) {
  return StockRepositoryImpl(ref.watch(databaseProvider));
});

// 2. Data providers (read)
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  return ref.watch(stockRepositoryProvider).getAllStockItems();
});

// 3. Filtered/computed providers
final lowStockItemsProvider = FutureProvider.autoDispose<List<StockItem>>((ref) async {
  final items = await ref.watch(stockProvider.future);
  return items.where((i) => i.isLowOnStock).toList();
});

// 4. UI state providers
final stockFilterProvider = StateProvider<StockFilter>((ref) => StockFilter.all);
final stockSearchProvider = StateProvider<String>((ref) => '');

// 5. Derived/filtered UI
final filteredStockProvider = FutureProvider<List<StockItem>>((ref) async {
  final all = await ref.watch(stockProvider.future);
  final filter = ref.watch(stockFilterProvider);
  final search = ref.watch(stockSearchProvider);
  return all.where((i) => _matches(i, filter, search)).toList();
});

// 6. Action providers
final addStockItemProvider = Provider<Future<void> Function(StockItem)>((ref) {
  return (item) async {
    final repo = ref.read(stockRepositoryProvider);
    await repo.addStockItem(item);
    ref.invalidate(stockProvider);
  };
});
```

**Rules:**
- Order: Repos → Data → Filtered → UI state → Derived → Actions
- One logical group per file
- Max 300 lines per provider file

---

### 9.2 Screen Organization

```dart
// File: lib/features/inventory/presentation/screens/stock_screen.dart

class StockScreen extends ConsumerWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: stockAsync.when(
        data: (items) => _StockBody(items: items),
        loading: () => _LoadingState(),
        error: (error, st) => _ErrorState(error: error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(title: Text('Stock'));
  }
}

class _StockBody extends StatelessWidget {
  const _StockBody({required this.items});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => StockItemTile(item: items[index]),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(context) => Center(child: CircularProgressIndicator());
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(context) => Center(child: Text('Error: $error'));
}
```

**Rules:**
- Primary widget: public (`StockScreen`)
- Helper widgets: private (`_StockBody`, `_LoadingState`)
- Extract if > 100 lines
- Use private widgets for single-use components

---

## 10. Generated Code

```
NEVER modify:
❌ *.g.dart files (Drift, code_gen)
❌ *.freezed.dart files (Freezed)
❌ *.config.dart files (GetIt)

ALWAYS regenerate:
✅ After entity changes: flutter pub run build_runner build
✅ After provider changes: flutter pub run build_runner build
✅ After schema changes: flutter pub run build_runner build
```

**Rules:**
- Generated code excluded from linting
- Regenerate before commit
- Never hand-edit generated code
- Include generated code in version control

---

## 11. Commit Message Rules

```
❌ "fix bug"
❌ "update code"
❌ "WIP"

✅ "feat: add stock filter by category"
✅ "fix: handle timeout in sync queue"
✅ "refactor: extract stock list widget"
✅ "chore: update dependencies"
✅ "test: add stock mapper tests"
```

**Rules:**
- Format: `[type]: [description]`
- Types: feat, fix, refactor, test, chore, docs
- Lowercase description
- Present tense
- Reference ticket if applicable

---

**Last updated:** 2024
**Valid for:** Flutter 3.x, Dart 3.x, Riverpod 2.4.x, Drift 2.13.x