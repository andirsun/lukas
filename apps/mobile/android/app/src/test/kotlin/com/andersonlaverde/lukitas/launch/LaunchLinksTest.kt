package com.andersonlaverde.lukitas.launch

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import com.andersonlaverde.lukitas.MainActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
}
