class CustomizationOption {
  final String name;
  final String value;
  final double price;

  CustomizationOption({
    required this.name,
    required this.value,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'price': price,
    };
  }

  factory CustomizationOption.fromMap(Map<String, dynamic> map) {
    return CustomizationOption(
      name: map['name'] ?? '',
      value: map['value'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}