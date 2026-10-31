package com.cardstack.card_stack

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Prevent screen capture, recording, and app switcher preview leaks for sensitive financial data
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
