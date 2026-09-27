import 'package:hive/hive.dart';

class Category extends HiveObject {
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.defaultAmount = 0.0,
    this.isSetback = false,
  });

  String id;
  String name;
  String icon;
  String colorHex;
  double defaultAmount;
  bool isSetback;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  int get typeId => 4;

  @override
  Category read(BinaryReader reader) {
    final fields = reader.readMap();
    return Category(
      id: fields['id'] as String,
      name: fields['name'] as String,
      icon: fields['icon'] as String,
      colorHex: fields['colorHex'] as String,
      defaultAmount: (fields['defaultAmount'] as num).toDouble(),
      isSetback: fields['isSetback'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'icon': obj.icon,
      'colorHex': obj.colorHex,
      'defaultAmount': obj.defaultAmount,
      'isSetback': obj.isSetback,
    });
  }
}
