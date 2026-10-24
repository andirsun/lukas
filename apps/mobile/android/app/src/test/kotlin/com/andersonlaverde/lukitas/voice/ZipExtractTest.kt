package com.andersonlaverde.lukitas.voice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class ZipExtractTest {
    @get:Rule val temp = TemporaryFolder()

    private fun zip(vararg entries: Pair<String, String?>): File {
        val file = temp.newFile("model.zip")
        ZipOutputStream(file.outputStream()).use { out ->
            for ((name, text) in entries) {
                out.putNextEntry(ZipEntry(name))
                if (text != null) out.write(text.toByteArray())
                out.closeEntry()
            }
        }
        return file
    }

    @Test
    fun unzipsTheModelFolder() {
        val into = File(temp.root, "voice")
        ZipExtract.unzip(zip("model/" to null, "model/am/final.mdl" to "weights"), into)
        assertEquals("weights", File(into, "model/am/final.mdl").readText())
    }

    @Test
    fun refusesAnEntryThatClimbsOutOfTheTarget() {
        val into = File(temp.root, "voice")
        assertThrows(SecurityException::class.java) {
            ZipExtract.unzip(zip("../evil.txt" to "x"), into)
        }
        assertFalse(File(temp.root, "evil.txt").exists())
    }

    @Test
    fun refusesASiblingFolderThatOnlySharesThePrefix() {
        val into = File(temp.root, "voice")
        assertThrows(SecurityException::class.java) {
            ZipExtract.unzip(zip("../voice-other/x.txt" to "x"), into)
        }
        assertFalse(File(temp.root, "voice-other/x.txt").exists())
        assertTrue(into.isDirectory)
    }
}
