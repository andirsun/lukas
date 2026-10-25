package com.andersonlaverde.lukitas

import android.content.Intent
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ExternalLinksTest {
    private val mailto =
        "mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20comentarios" +
            "&body=%0A%0AVersi%C3%B3n%20de%20Lukitas%3A%201.2.3%0AIdioma%3A%20es"

    @Test
    fun `mailto opens the email apps with the address, the subject and the body decoded`() {
        val intent = ExternalLinks.intentFor(mailto)!!
        assertEquals(Intent.ACTION_SENDTO, intent.action)
        // Only email apps answer a bare mailto: data.
        assertEquals("mailto:", intent.dataString)
        assertArrayEquals(arrayOf("lukitas@andersonlaverde.com"), intent.getStringArrayExtra(Intent.EXTRA_EMAIL))
        assertEquals("Lukitas: comentarios", intent.getStringExtra(Intent.EXTRA_SUBJECT))
        assertEquals("\n\nVersión de Lukitas: 1.2.3\nIdioma: es", intent.getStringExtra(Intent.EXTRA_TEXT))
    }

    @Test
    fun `a plus in the body stays a plus, and the scheme may be in capitals`() {
        val intent = ExternalLinks.intentFor("MAILTO:a@b.co?body=1%2B1%3D2+3")!!
        assertEquals("1+1=2+3", intent.getStringExtra(Intent.EXTRA_TEXT))
        assertNull(intent.getStringExtra(Intent.EXTRA_SUBJECT))
    }

    @Test
    fun `a link cannot add recipients or files to the message`() {
        val intent = ExternalLinks.intentFor("mailto:a@b.co?cc=x@y.co&bcc=z@y.co&attach=content://x&subject=Hi")!!
        assertArrayEquals(arrayOf("a@b.co"), intent.getStringArrayExtra(Intent.EXTRA_EMAIL))
        assertNull(intent.getStringArrayExtra(Intent.EXTRA_CC))
        assertNull(intent.getStringArrayExtra(Intent.EXTRA_BCC))
        assertFalse(intent.hasExtra(Intent.EXTRA_STREAM))
        assertEquals("Hi", intent.getStringExtra(Intent.EXTRA_SUBJECT))
    }

    @Test
    fun `web pages open as a browsable view`() {
        val https = ExternalLinks.intentFor("https://app.example.com/en")!!
        assertEquals(Intent.ACTION_VIEW, https.action)
        assertEquals("https://app.example.com/en", https.dataString)
        assertTrue(https.categories.contains(Intent.CATEGORY_BROWSABLE))
        assertEquals("http://10.0.2.2:3000", ExternalLinks.intentFor("http://10.0.2.2:3000")!!.dataString)
    }

    @Test
    fun `javascript, intent and every other scheme are refused`() {
        for (address in listOf(
            "javascript:alert(1)",
            "JavaScript:alert(1)",
            " javascript:alert(1)",
            "java\nscript:alert(1)",
            "intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end",
            "intent:#Intent;action=android.intent.action.CALL;end",
            "file:///data/data/com.andersonlaverde.lukitas/databases/x",
            "content://com.android.contacts/contacts",
            "tel:+34600000000",
            "sms:+34600000000?body=hi",
            "data:text/html,<script>alert(1)</script>",
            "market://details?id=x",
            "android-app://com.example",
            "ftp://example.com/file",
            "//example.com",
            "example.com",
            ":mailto",
            "",
        )) {
            assertNull(address, ExternalLinks.intentFor(address))
        }
        assertNull(ExternalLinks.intentFor(null))
    }

    @Test
    fun `the scheme is what comes before the first colon, well formed`() {
        assertEquals("mailto", ExternalLinks.schemeOf("MailTo:a@b.co"))
        assertEquals("https", ExternalLinks.schemeOf("https://x"))
        assertNull(ExternalLinks.schemeOf("1http://x"))
        assertNull(ExternalLinks.schemeOf("ht tp://x"))
        assertNull(ExternalLinks.schemeOf("no scheme"))
    }
}
