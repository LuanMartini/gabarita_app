package com.example.gabarita_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DailyChallengeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_challenge)
            val question = widgetData.getString(
                "daily_question",
                "Abra o Gabarita para carregar o desafio."
            )
            val subject = widgetData.getString("daily_subject", "Desafio do Dia")
            val topic = widgetData.getString("daily_topic", "Banco local")
            val result = widgetData.getString("daily_result", "")

            views.setTextViewText(R.id.daily_title, "$subject - $topic")
            views.setTextViewText(R.id.daily_question, question)
            views.setTextViewText(
                R.id.daily_result,
                if (result.isNullOrBlank()) "Toque em A, B, C ou D para responder." else result
            )

            setAnswerIntent(context, views, R.id.daily_answer_a, "A")
            setAnswerIntent(context, views, R.id.daily_answer_b, "B")
            setAnswerIntent(context, views, R.id.daily_answer_c, "C")
            setAnswerIntent(context, views, R.id.daily_answer_d, "D")
            views.setOnClickPendingIntent(
                R.id.widget_daily_container,
                launchIntent(context, "daily-challenge")
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun setAnswerIntent(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        option: String
    ) {
        views.setOnClickPendingIntent(
            viewId,
            HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("gabarita://daily-answer?selected=$option")
            )
        )
    }
}

class PerformanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val series = widgetData.getString("weekly_accuracy_series", "0,0,0,0,0,0,0")
            ?.split(",")
            ?.mapNotNull { it.toIntOrNull()?.coerceIn(0, 100) }
            ?.take(7)
            ?.let { values -> if (values.size == 7) values else values + List(7 - values.size) { 0 } }
            ?: List(7) { 0 }
        val latest = widgetData.getInt("weekly_accuracy_latest", series.lastOrNull() ?: 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_performance)
            views.setImageViewBitmap(R.id.performance_chart, drawPerformanceChart(series))
            views.setTextViewText(R.id.performance_summary, "Hoje: $latest% de acertos")
            views.setOnClickPendingIntent(
                R.id.widget_performance_container,
                launchIntent(context, "stats")
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun drawPerformanceChart(values: List<Int>): Bitmap {
        val width = 520
        val height = 180
        val padding = 18f
        val gap = 10f
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(34, 48, 68)
            strokeWidth = 2f
        }
        val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(77, 163, 255)
        }
        val emptyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(38, 54, 74)
        }

        canvas.drawLine(padding, height - padding, width - padding, height - padding, gridPaint)
        val barWidth = (width - padding * 2 - gap * 6) / 7f
        values.forEachIndexed { index, value ->
            val left = padding + index * (barWidth + gap)
            val top = padding + (100 - value) / 100f * (height - padding * 2)
            val rect = RectF(left, top, left + barWidth, height - padding)
            canvas.drawRoundRect(rect, 10f, 10f, if (value == 0) emptyPaint else barPaint)
        }

        return bitmap
    }
}

class QuickStatsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val accuracy = widgetData.getInt("quick_accuracy_percent", 0)
        val total = widgetData.getInt("quick_total_answered", 0)
        val today = widgetData.getInt("quick_today_count", 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_stats)
            views.setTextViewText(R.id.quick_accuracy, "$accuracy%")
            views.setTextViewText(R.id.quick_answered, "$total questoes respondidas")
            views.setTextViewText(R.id.quick_today, "$today feitas hoje")
            views.setOnClickPendingIntent(
                R.id.widget_quick_stats_container,
                launchIntent(context, "stats")
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class LastTopicWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val topic = widgetData.getString("last_topic", "Nenhum topico ainda")
        val subject = widgetData.getString("last_subject", "Comece um treino")
        val source = widgetData.getString("last_exam_source", "Banco local")

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_last_topic)
            views.setTextViewText(R.id.last_topic_title, topic)
            views.setTextViewText(R.id.last_topic_subject, "$subject - $source")
            views.setOnClickPendingIntent(
                R.id.widget_last_topic_container,
                launchIntent(context, "last-topic")
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class ScannerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_scanner)
            views.setOnClickPendingIntent(
                R.id.widget_scanner_container,
                launchIntent(context, "scanner")
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

private fun launchIntent(context: Context, route: String) =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("gabarita://$route")
    )
