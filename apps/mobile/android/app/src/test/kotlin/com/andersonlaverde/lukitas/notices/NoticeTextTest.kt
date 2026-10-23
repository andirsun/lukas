package com.andersonlaverde.lukitas.notices

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class NoticeTextTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `at 9 the payments due today are joined naturally in Spanish`() {
        assertEquals("Hoy vence Arriendo", NoticeText.due(context, listOf("Arriendo"), "es"))
        assertEquals("Hoy vencen Arriendo y Spotify", NoticeText.due(context, listOf("Arriendo", "Spotify"), "es"))
        assertEquals(
            "Hoy vencen Arriendo, Netflix y Spotify",
            NoticeText.due(context, listOf("Arriendo", "Netflix", "Spotify"), "es"),
        )
    }

    @Test
    fun `and in English`() {
        assertEquals("Rent is due today", NoticeText.due(context, listOf("Rent"), "en"))
        assertEquals("Rent and Spotify are due today", NoticeText.due(context, listOf("Rent", "Spotify"), "en"))
        assertEquals(
            "Rent, Netflix and Spotify are due today",
            NoticeText.due(context, listOf("Rent", "Netflix", "Spotify"), "en"),
        )
    }

    @Test
    fun `Spanish says e before a word that starts with the sound i`() {
        assertEquals("Hoy vencen Arriendo e Internet", NoticeText.due(context, listOf("Arriendo", "Internet"), "es"))
        assertEquals("Hoy vencen Luz e Hipoteca", NoticeText.due(context, listOf("Luz", "Hipoteca"), "es"))
        // Not a vowel sound of i: Hielo, Iatrogenia.
        assertEquals("Hoy vencen Luz y Hielo", NoticeText.due(context, listOf("Luz", "Hielo"), "es"))
        assertEquals("Hoy vencen Luz y Spotify", NoticeText.due(context, listOf("Luz", "Spotify"), "es"))
    }

    @Test
    fun `blank and repeated names are left out`() {
        assertEquals(
            "Hoy vencen Arriendo y Spotify",
            NoticeText.due(context, listOf(" Arriendo ", "", "Spotify", "Arriendo"), "es"),
        )
    }

    @Test
    fun `the guest warning`() {
        assertEquals(
            "Tus datos se borrarán en 15 días si no agregas tu correo",
            NoticeText.guestWarning(context, "es"),
        )
        assertEquals(
            "Your data will be deleted in 15 days if you don't add your email",
            NoticeText.guestWarning(context, "en"),
        )
    }

    @Test
    @Config(qualifiers = "es")
    fun `no language chosen follows the phone, Spanish here, and a language the app lacks is Spanish`() {
        assertEquals("Hoy vence Arriendo", NoticeText.due(context, listOf("Arriendo"), null))
        assertEquals("Hoy vence Arriendo", NoticeText.due(context, listOf("Arriendo"), "fr"))
    }

    @Test
    @Config(qualifiers = "en")
    fun `no language chosen follows the phone, English here`() {
        assertEquals("Rent is due today", NoticeText.due(context, listOf("Rent"), null))
    }
}
