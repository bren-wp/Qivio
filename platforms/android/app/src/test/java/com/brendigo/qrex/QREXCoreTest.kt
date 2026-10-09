package com.brendigo.qrex

import org.junit.Assert.*
import org.junit.Test

class QREXCoreTest {
    @Test fun wifiEscapesDelimiters() {
        val raw = QRContent.wifi("Office;P:fake", "a\\b:c")
        assertEquals("Office;P:fake", QRContent.wifiField(raw, "S"))
        assertEquals("a\\b:c", QRContent.wifiField(raw, "P"))
    }

    @Test fun longQrIsRejected() {
        assertFalse(QRContent.canRender(""))
        assertFalse(QRContent.canRender("x".repeat(1501)))
        assertTrue(QRContent.canRender("hello"))
    }
}
