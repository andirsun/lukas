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
        assertEquals(MainActivity::class.java.name, add.component?.className)
        assertEquals("lukitas://capture", LaunchLinks.intent(context, LaunchLinks.CAPTURE).dataString)
    }

    @Test
    fun `only lukitas add and capture links are taken`() {
        assertEquals("lukitas://add", LaunchLinks.linkOf(LaunchLinks.intent(context, LaunchLinks.ADD)))
        assertEquals("lukitas://capture", LaunchLinks.linkOf(Intent(Intent.ACTION_VIEW, Uri.parse("lukitas://capture"))))
        assertNull(LaunchLinks.linkOf(Intent(Intent.ACTION_VIEW, Uri.parse("lukitas://settings"))))
        assertNull(LaunchLinks.linkOf(Intent(Intent.ACTION_VIEW, Uri.parse("https://app-lukas.andersonlaverde.com/auth/verify"))))
        assertNull(LaunchLinks.linkOf(Intent(Intent.ACTION_MAIN)))
        assertNull(LaunchLinks.linkOf(null))
    }

    @Test
    fun `reopened from recents, the old link is not acted on again`() {
        val again = LaunchLinks.intent(context, LaunchLinks.CAPTURE)
            .addFlags(Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)
        assertNull(LaunchLinks.linkOf(again))
    }
}
