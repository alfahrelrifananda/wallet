package com.alfahrel.wallet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WalletWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_balance)
            
            val prefs = HomeWidgetPlugin.getData(context)
            val balance = prefs.getString("balance", "$0")
            
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_label, "Total Balance")
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}