import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> icons = {
    'account_balance_wallet': Icons.account_balance_wallet,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'receipt_long': Icons.receipt_long,
    'medical_services': Icons.medical_services,
    'payments': Icons.payments,
    'business': Icons.business,
    'card_giftcard': Icons.card_giftcard,
    'more_horiz': Icons.more_horiz,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'shopping_cart': Icons.shopping_cart,
    'local_gas_station': Icons.local_gas_station,
    'flight': Icons.flight,
    'home': Icons.home,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'sports_esports': Icons.sports_esports,
    'sports_soccer': Icons.sports_soccer,
    'fitness_center': Icons.fitness_center,
    'medication': Icons.medication,
    'school': Icons.school,
    'work': Icons.work,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'checkroom': Icons.checkroom,
    'dry_cleaning': Icons.dry_cleaning,
    'build': Icons.build,
    'computer': Icons.computer,
    'headphones': Icons.headphones,
    'book': Icons.book,
    'brush': Icons.brush,
    'category': Icons.category,
  };

  static String getIconName(IconData icon) {
    return icons.entries
        .firstWhere(
          (entry) => entry.value.codePoint == icon.codePoint,
          orElse: () => const MapEntry('category', Icons.category),
        )
        .key;
  }

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.category;
  }
}
