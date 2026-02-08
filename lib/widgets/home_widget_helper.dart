import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetHelper {
  static Future<void> updateBalance({
    required double balance,
    required String currencySymbol,
  }) async {
    try {
      final formatter = NumberFormat('#,##0', 'en_US');
      final balanceText = '$currencySymbol${formatter.format(balance)}';

      await HomeWidget.saveWidgetData<String>('balance', balanceText);
      await HomeWidget.updateWidget(
        androidName: 'WalletWidgetProvider',
        iOSName: 'WalletWidget',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
