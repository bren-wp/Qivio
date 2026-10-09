package com.brendigo.qrex

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Device-backed regression tests: never write Wi-Fi credentials to plaintext preferences. */
@RunWith(AndroidJUnit4::class)
class QREXStorageTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun savedWifiPasswordIsEncryptedAndCanBeRestored() {
        val store = QREXStore(context)
        store.clearAll()
        val raw = QRContent.wifi("Home", "secret_test_pass_2026")
        store.save(raw)
        assertEquals(raw, store.items.firstOrNull()?.raw)
        val prefs = context.getSharedPreferences("qrex.user", 0)
        val json = prefs.getString("history", "") ?: ""
        assertFalse(json.contains("secret_test_pass_2026"))
        assertTrue(json.contains("qrex-gcm:v1:"))
        val reopened = QREXStore(context)
        assertEquals(raw, reopened.items.firstOrNull()?.raw)
        reopened.clearAll()
        assertFalse(prefs.contains("history"))
    }

    @Test
    fun oldUnencryptedWifiHistoryIsMigratedOnStartup() {
        val prefs = context.getSharedPreferences("qrex.user", 0)
        prefs.edit().clear().commit()
        val raw = QRContent.wifi("Office", "legacy_plain_password")
        val json = org.json.JSONArray().put(org.json.JSONObject()
            .put("raw", raw).put("timestamp", 123L).put("saved", true))
        assertTrue(prefs.edit().putString("history", json.toString()).commit())
        val reopened = QREXStore(context)
        assertEquals(raw, reopened.items.firstOrNull()?.raw)
        val stored = prefs.getString("history", "") ?: ""
        assertFalse(stored.contains("legacy_plain_password"))
        assertTrue(stored.contains("qrex-gcm:v1:"))
        reopened.clearAll()
    }
}
