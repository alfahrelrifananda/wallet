import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/helper/icon.dart';

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final IconData icon;
  final Color color;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
    'initialBalance': initialBalance,
    'iconName': IconHelper.getIconName(icon),
    'color': color.value,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    type: AccountType.values.firstWhere((e) => e.toString() == json['type']),
    initialBalance: json['initialBalance'],
    icon: IconHelper.getIcon(json['iconName'] ?? 'account_balance_wallet'),
    color: Color(json['color']),
  );
}

enum AccountType { wallet, bank, card, savings, investment }

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final bool isDeletable;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.isDeletable = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': IconHelper.getIconName(icon),
    'color': color.value,
    'isExpense': isExpense,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    icon: IconHelper.getIcon(json['iconName'] ?? 'more_horiz'),
    color: Color(json['color']),
    isExpense: json['isExpense'],
  );
}

class Transaction {
  final String id;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String accountId;
  final String categoryId;
  final String note;

  Transaction({
    required this.id,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.accountId,
    required this.categoryId,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'isIncome': isIncome,
    'date': date.toIso8601String(),
    'accountId': accountId,
    'categoryId': categoryId,
    'note': note,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'],
    isIncome: json['isIncome'],
    date: DateTime.parse(json['date']),
    accountId: json['accountId'],
    categoryId: json['categoryId'],
    note: json['note'] ?? '',
  );
}
