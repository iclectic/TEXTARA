package com.textara.textara

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val pending = mutableListOf<Map<String, String>>()
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePending" -> {
                        val copy = pending.toList()
                        pending.clear()
                        result.success(copy)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        capture(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        capture(intent)
    }

    private fun capture(intent: Intent?) {
        if (intent == null) return
        val produced = when (intent.action) {
            Intent.ACTION_VIEW -> {
                val data = intent.data
                if (data == null) false else enqueueUri(data)
            }
            Intent.ACTION_SEND -> {
                val uri = readStream(intent)
                if (uri == null) false else enqueueUri(uri)
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = readStreams(intent)
                var any = false
                uris?.forEach { uri ->
                    if (enqueueUri(uri)) any = true
                }
                any
            }
            else -> false
        }
        if (!produced) return
        setIntent(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER))
        channel?.invokeMethod("incomingAvailable", null)
    }

    private fun enqueueUri(uri: Uri): Boolean {
        if (uri.scheme == "textara" && uri.host == "book") {
            val id = uri.path?.trim('/')?.substringBefore('/')?.trim().orEmpty()
            if (id.isEmpty()) return false
            pending.add(mapOf("type" to "book", "value" to id))
            return true
        }
        val path = materialise(uri) ?: return false
        pending.add(mapOf("type" to "file", "value" to path))
        return true
    }

    private fun materialise(uri: Uri): String? {
        val name = sanitize(displayName(uri))
        val extension = name.substringAfterLast('.', "").lowercase()
        if (extension != "epub" && extension != "pdf") return null
        if (uri.scheme == "file") return uri.path

        val directory = File(cacheDir, "incoming").apply { mkdirs() }
        val dest = File(directory, "${UUID.randomUUID()}_$name")
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            dest.absolutePath
        } catch (_: Exception) {
            dest.delete()
            null
        }
    }

    private fun displayName(uri: Uri): String {
        if (uri.scheme == "content") {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index >= 0) {
                            val name = cursor.getString(index)
                            if (!name.isNullOrBlank()) return name
                        }
                    }
                }
        }
        return uri.lastPathSegment ?: "book"
    }

    private fun sanitize(name: String): String {
        val base = name.substringAfterLast('/').substringAfterLast('\\')
        val cleaned = base.replace(Regex("[^A-Za-z0-9._ -]"), "_").take(120)
        return cleaned.ifBlank { "book" }
    }

    private fun readStream(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun readStreams(intent: Intent): ArrayList<Uri>? {
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }
    }

    companion object {
        private const val CHANNEL = "com.textara.textara/incoming"
    }
}
