package com.bariqon.mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) — required by local_auth's
// biometric prompt (App Lock), which needs a FragmentActivity host.
class MainActivity : FlutterFragmentActivity()
