package com.andersonlaverde.lukitas.files

import java.io.ByteArrayInputStream
import java.io.InputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FileTransferTest {
    private fun bytes(count: Int) = ByteArray(count) { (it % 251).toByte() }

    @Test
    fun `a file within the limit is read whole`() {
        val data = bytes(1000)
        val read = FileTransfer.readBounded(ByteArrayInputStream(data), 1000)
        assertArrayEquals(data, read)
    }

    @Test
    fun `a file one byte over the limit is refused`() {
        assertNull(FileTransfer.readBounded(ByteArrayInputStream(bytes(1001)), 1000))
    }

    @Test
    fun `an empty file is read as empty`() {
        assertEquals(0, FileTransfer.readBounded(ByteArrayInputStream(ByteArray(0)), 1000)?.size)
    }

    @Test
    fun `a file larger than the limit is never read past the limit plus one`() {
        // A source that would go on for a gigabyte: reading stops just past the limit.
        var served = 0L
        val endless = object : InputStream() {
            override fun read(): Int {
                served += 1
                return 1
            }

            override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
                served += length
                return length
            }
        }
        assertNull(FileTransfer.readBounded(endless, 5 * 1024 * 1024))
        assertTrue("read $served bytes", served <= 5 * 1024 * 1024 + 8192 + 1)
    }

    @Test
    fun `a stream that hands out a few bytes at a time is read whole`() {
        val data = bytes(5000)
        val slow = object : InputStream() {
            private var at = 0
            override fun read(): Int = if (at < data.size) data[at++].toInt() and 0xff else -1
            override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
                if (at >= data.size) return -1
                val count = minOf(7, length, data.size - at)
                System.arraycopy(data, at, buffer, offset, count)
                at += count
                return count
            }
        }
        assertArrayEquals(data, FileTransfer.readBounded(slow, 5000))
    }

    @Test
    fun `a name loses its folders and keeps its extension`() {
        assertEquals("budge.csv", FileTransfer.safeName("budge.csv"))
        assertEquals("passwd", FileTransfer.safeName("../../etc/passwd"))
        assertEquals("a.csv", FileTransfer.safeName("dir\\sub\\a.csv"))
    }

    @Test
    fun `a name with nothing usable gets the app's own`() {
        assertEquals("lukitas", FileTransfer.safeName(""))
        assertEquals("lukitas", FileTransfer.safeName("   "))
        assertEquals("lukitas", FileTransfer.safeName("../"))
        assertEquals("lukitas", FileTransfer.safeName(".."))
    }

    @Test
    fun `a name has no control characters or leading dots`() {
        assertEquals("hidden.csv", FileTransfer.safeName(".hidden.csv"))
        assertEquals("ab.csv", FileTransfer.safeName("a\u0000b\n.csv"))
    }

    @Test
    fun `a long name is cut but keeps its extension`() {
        val name = "x".repeat(300) + ".csv"
        val safe = FileTransfer.safeName(name)
        assertTrue(safe.length <= 120)
        assertTrue(safe.endsWith(".csv"))
    }

    @Test
    fun `mime types are read from the call and fall back to anything`() {
        assertEquals(listOf("text/csv", "text/plain"), FileTransfer.mimeTypesOf(listOf("text/csv", "text/plain")))
        assertEquals(listOf("*/*"), FileTransfer.mimeTypesOf(null))
        assertEquals(listOf("*/*"), FileTransfer.mimeTypesOf(emptyList<String>()))
        assertEquals(listOf("text/csv"), FileTransfer.mimeTypesOf(listOf("text/csv", 3, "")))
    }

    @Test
    fun `the limit asked for is a sane number`() {
        assertEquals(5 * 1024 * 1024, FileTransfer.limitOf(5 * 1024 * 1024))
        assertEquals(FileTransfer.DEFAULT_LIMIT, FileTransfer.limitOf(null))
        assertEquals(FileTransfer.DEFAULT_LIMIT, FileTransfer.limitOf(-4))
        assertEquals(FileTransfer.DEFAULT_LIMIT, FileTransfer.limitOf("big"))
        assertEquals(FileTransfer.MAX_LIMIT, FileTransfer.limitOf(Int.MAX_VALUE))
    }
}
