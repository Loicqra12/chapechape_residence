package com.chapechape.chapechape_partner

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15+ / Play Console : fenêtre en bord à bord (API recommandées par Google).
        // Les insets sont gérés côté Flutter (SystemUiMode.edgeToEdge, SafeArea, AppBar/SliverAppBar).
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
