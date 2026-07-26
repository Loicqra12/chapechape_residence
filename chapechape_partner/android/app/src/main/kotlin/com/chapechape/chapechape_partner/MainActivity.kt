package com.chapechape.chapechape_partner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Bord à bord : FlutterActivity n’hérite pas de ComponentActivity → pas d’enableEdgeToEdge().
        // WindowCompat fonctionne sur Activity et reste aligné avec SystemUiMode.edgeToEdge côté Flutter.
        WindowCompat.setDecorFitsSystemWindows(window, false)
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
            // Canaux legacy locaux Partner (rétrocompat)
            Triple("chapechape_partner_channel", "Partner", NotificationManager.IMPORTANCE_HIGH),
            Triple("chapechape_partner_reminders", "Rappels Partner", NotificationManager.IMPORTANCE_DEFAULT),
        )

        channels.forEach { (id, name, importance) ->
            val channel = NotificationChannel(id, name, importance).apply {
                description = "Notifications ChapeChape Partner — $name"
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }
    }
}
