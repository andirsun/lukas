package com.andersonlaverde.lukitas.launch

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import com.andersonlaverde.lukitas.MainActivity
import com.andersonlaverde.lukitas.widget.ServerSetting
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class LaunchLinksTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `the widget's buttons and the tile start this app on their link`() {
        val add = LaunchLinks.intent(context, LaunchLinks.ADD)
        assertEquals(Intent.ACTION_VIEW, add.action)
        assertEquals("lukitas://add", add.dataString)
        // The app's own, not-exported entry for its links: no other app can start it.
        assertEquals("com.andersonlaverde.lukitas.LaunchLinkAlias", add.component?.className)
        assertEquals("lukitas://capture", LaunchLinks.intent(context, LaunchLinks.CAPTURE).dataString)
    }

    private fun viaAlias(link: String) =
        Intent(Intent.ACTION_VIEW, Uri.parse(link)).setClassName(context, "com.andersonlaverde.lukitas.LaunchLinkAlias")

    @Test
    fun `only lukitas add, capture and due links are taken, and only through the app's own entry`() {
        assertEquals("lukitas://add", LaunchLinks.linkOf(LaunchLinks.intent(context, LaunchLinks.ADD)))
        assertEquals("lukitas://capture", LaunchLinks.linkOf(viaAlias("lukitas://capture")))
        // The "Hoy vence…" notice opens home through the same entry.
        assertEquals("lukitas://due", LaunchLinks.linkOf(LaunchLinks.intent(context, LaunchLinks.DUE)))
        // And the guest warning opens "Guarda tu progreso".
        assertEquals("lukitas://progress", LaunchLinks.linkOf(LaunchLinks.intent(context, LaunchLinks.PROGRESS)))
        assertNull(LaunchLinks.linkOf(viaAlias("lukitas://settings")))
        assertNull(LaunchLinks.linkOf(viaAlias("https://app-lukas.andersonlaverde.com/auth/verify")))
        assertNull(LaunchLinks.linkOf(Intent(Intent.ACTION_MAIN)))
        assertNull(LaunchLinks.linkOf(null))
    }

    @Test
    fun `another app starting the exported launcher activity with the link does not open capture`() {
        val explicit = Intent(Intent.ACTION_VIEW, Uri.parse("lukitas://capture"))
            .setClass(context, MainActivity::class.java)
        assertNull(LaunchLinks.linkOf(explicit))
        assertNull(LaunchLinks.linkOf(Intent(Intent.ACTION_VIEW, Uri.parse("lukitas://capture"))))
    }

    @Test
    fun `reopened from recents, the old link is not acted on again`() {
        val again = LaunchLinks.intent(context, LaunchLinks.CAPTURE)
            .addFlags(Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)
        assertNull(LaunchLinks.linkOf(again))
    }

    // --- Web links (the magic link) --------------------------------------------------------------

    private fun view(link: String) = Intent(Intent.ACTION_VIEW, Uri.parse(link)).setClass(context, MainActivity::class.java)

    private val verify = "https://app-lukas.andersonlaverde.com/auth/verify?email=ana%40correo.com&code=123456"

    @Test
    fun `a web link to the configured server's host goes on to the app`() {
        assertFalse(LaunchLinks.isForeignWebLink(view(verify), "app-lukas.andersonlaverde.com"))
        // Hosts are not case-sensitive.
        assertFalse(LaunchLinks.isForeignWebLink(view(verify), "App-Lukas.AndersonLaverde.com"))
        // The dev stack, from the emulator.
        assertFalse(LaunchLinks.isForeignWebLink(view("http://10.0.2.2:3000/auth/verify?code=1"), "10.0.2.2"))
    }

    @Test
    fun `a web link to any other host is dropped, so no app can sign the person into its account`() {
        assertTrue(LaunchLinks.isForeignWebLink(view("https://evil.example/auth/verify?email=x%40y.z&code=1"), "app-lukas.andersonlaverde.com"))
        assertTrue(LaunchLinks.isForeignWebLink(view(verify), "lukitas.example.org"))
        // A server setting that cannot be read is no host at all: nothing goes on.
        assertTrue(LaunchLinks.isForeignWebLink(view(verify), null))
        assertTrue(LaunchLinks.isForeignWebLink(view("https:///auth/verify"), "app-lukas.andersonlaverde.com"))
    }

    @Test
    fun `what is not a web link is left to the other rules`() {
        assertFalse(LaunchLinks.isForeignWebLink(LaunchLinks.intent(context, LaunchLinks.ADD), null))
        assertFalse(LaunchLinks.isForeignWebLink(Intent(Intent.ACTION_MAIN), null))
        assertFalse(LaunchLinks.isForeignWebLink(null, null))
    }

    @Test
    fun `the configured server is the one chosen in Settings, else the build's default`() {
        val default = "https://app-lukas.andersonlaverde.com"
        assertEquals("app-lukas.andersonlaverde.com", LaunchLinks.serverHost(ServerSetting.Default, default))
        assertEquals("lukitas.example.org", LaunchLinks.serverHost(ServerSetting.Chosen("https://lukitas.example.org/"), default))
        assertNull(LaunchLinks.serverHost(ServerSetting.Unreadable, default))
    }
}
