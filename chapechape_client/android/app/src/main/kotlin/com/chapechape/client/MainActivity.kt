package com.chapechape.client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return

        val channels = listOf(
            Triple("chapechape_bookings", "Réservations", NotificationManager.IMPORTANCE_HIGH),
            Triple("chapechape_payments", "Paiements", NotificationManager.IMPORTANCE_HIGH),
            Triple("chapechape_messages", "Messages", NotificationManager.IMPORTANCE_HIGH),
            Triple("chapechape_promotions", "Promotions", NotificationManager.IMPORTANCE_DEFAULT),
            Triple("chapechape_system", "Système", NotificationManager.IMPORTANCE_DEFAULT),
        )

        channels.forEach { (id, name, importance) ->
            val channel = NotificationChannel(id, name, importance).apply {
                description = "Notifications ChapeChape — $name"
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }
    }
}
