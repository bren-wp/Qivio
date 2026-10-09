package com.brendigo.qrex

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONArray
import org.json.JSONObject

data class QRRecord(val raw: String, val timestamp: Long, val saved: Boolean)

object QRContent {
    fun isWifi(raw: String): Boolean = raw.startsWith("WIFI:", ignoreCase = true)

    fun wifiField(raw: String, name: String): String? {
        if (!isWifi(raw) || name !in setOf("S", "P", "T", "H")) return null
        val fields = mutableMapOf<String, String>()
        val current = StringBuilder()
        var escaped = false
        fun consume() {
            val text = current.toString()
            val sep = text.indexOf(':')
            if (sep > 0) fields[text.substring(0, sep)] = text.substring(sep + 1)
            current.clear()
        }
        for (char in raw.drop(5)) {
            when {
                escaped -> { current.append(char); escaped = false }
                char.code == 92 -> escaped = true
                char == ';' -> consume()
                else -> current.append(char)
            }
        }
        if (escaped) return null
        if (current.isNotEmpty()) consume()
        return fields[name]
    }

    fun wifi(ssid: String, password: String): String {
        fun escape(text: String): String = buildString {
            for (ch in text) {
                if (ch == ';' || ch == ':' || ch == ',' || ch.code == 92) append(Char(92))
                append(ch)
            }
        }
        return "WIFI:T:${if (password.isBlank()) "nopass" else "WPA"};S:${escape(ssid)};P:${escape(password)};;"
    }

    fun safeUrl(raw: String): Uri? {
        if (raw != raw.trim() || raw.any { it.isWhitespace() || it.isISOControl() || it.code == 92 }) return null
        return runCatching {
            val uri = Uri.parse(raw)
            if (uri.scheme?.lowercase() !in setOf("http", "https") ||
                uri.host.isNullOrBlank() || (uri.encodedAuthority?.contains("@") == true)) null else uri
        }.getOrNull()
    }

    fun label(raw: String): String = when {
        isWifi(raw) -> wifiField(raw, "S") ?: "Wi-Fi mreža"
        safeUrl(raw) != null -> safeUrl(raw)?.host ?: raw
        else -> raw.replace("\n", " ").take(56)
    }

    fun canRender(raw: String): Boolean =
        raw.isNotBlank() && raw.toByteArray(Charsets.UTF_8).size <= 1500
}

class QREXStore(context: Context) {
    private val preferences: SharedPreferences =
        context.getSharedPreferences("qrex.user", Context.MODE_PRIVATE)
    val items = mutableStateListOf<QRRecord>()
    var historyEnabled by mutableStateOf(preferences.getBoolean("historyEnabled", true))
        private set
    var lightMode by mutableStateOf(preferences.getBoolean("lightMode", false))
        private set
    var language by mutableStateOf(preferences.getString("language", "en") ?: "en")
        private set

    init {
        runCatching {
            val stored = JSONArray(preferences.getString("history", "[]") ?: "[]")
            val seen = mutableSetOf<String>()
            for (i in 0 until minOf(stored.length(), 250)) {
                val item = stored.optJSONObject(i) ?: continue
                val raw = item.optString("raw")
                if (raw.isBlank() || raw.length > 10000 || !seen.add(raw)) continue
                items += QRRecord(raw, item.optLong("timestamp"), item.optBoolean("saved"))
            }
        }
    }

    fun record(raw: String) {
        if (!historyEnabled || QRContent.isWifi(raw) || raw.isBlank()) return
        update(raw, items.find { it.raw == raw }?.saved == true)
    }

    fun save(raw: String) {
        if (raw.isBlank()) return
        update(raw, true)
    }

    private fun update(raw: String, saved: Boolean) {
        items.removeAll { it.raw == raw }
        items.add(0, QRRecord(raw, System.currentTimeMillis(), saved))
        if (items.size > 250) {
            val lastUnsaved = items.indexOfLast { !it.saved }
            items.removeAt(if (lastUnsaved >= 0) lastUnsaved else items.lastIndex)
        }
        persist()
    }

    fun remove(item: QRRecord) {
        items.remove(item)
        persist()
    }

    fun clearHistory() {
        items.removeAll { !it.saved }
        persist()
    }

    fun clearAll() {
        items.clear()
        preferences.edit().clear().apply()
        historyEnabled = true
        lightMode = false
        language = "en"
    }

    fun updateLanguage(value: String) {
        require(value == "system" || value in QREXStrings.languages)
        language = value
        preferences.edit().putString("language", value).apply()
    }

    fun updateHistoryEnabled(value: Boolean) {
        historyEnabled = value
        preferences.edit().putBoolean("historyEnabled", value).apply()
    }

    fun updateLightMode(value: Boolean) {
        lightMode = value
        preferences.edit().putBoolean("lightMode", value).apply()
    }

    private fun persist() {
        val array = JSONArray()
        items.forEach {
            array.put(JSONObject().put("raw", it.raw)
                .put("timestamp", it.timestamp).put("saved", it.saved))
        }
        preferences.edit().putString("history", array.toString()).apply()
    }
}
