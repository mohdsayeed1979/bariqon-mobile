package com.bariqon.mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) — required by local_auth's
// BiometricPrompt integration for the App Lock feature.
class MainActivity : FlutterFragmentActivity()
