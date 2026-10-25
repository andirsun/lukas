package com.andersonlaverde.lukitas.files

import java.io.ByteArrayOutputStream
import java.io.InputStream

/**
 * The parts of [FilesChannel] that do not need Android: reading a file within a limit, and the
 * names and numbers the Dart side hands over. Kept apart so they run as plain JVM tests.
 */
object FileTransfer {
    /** The limit when the caller gives none (the import's, 5 MB). */
    const val DEFAULT_LIMIT = 5 * 1024 * 1024

    /** No limit asked for goes past this: a file is held in memory whole. */
    const val MAX_LIMIT = 32 * 1024 * 1024

    private const val MAX_NAME = 120
    private const val FALLBACK_NAME = "lukitas"

    /**
     * Reads [input] whole, or null when it holds more than [limit] bytes. It never reads more than
     * one byte past [limit], so a huge (or endless) document costs a few kilobytes of memory, not
     * its size.
     */
    fun readBounded(input: InputStream, limit: Int): ByteArray? {
        val out = ByteArrayOutputStream(minOf(limit, 64 * 1024))
        val buffer = ByteArray(8192)
        var total = 0L
        while (true) {
            // Never ask for more than what is left of the limit plus the one byte that proves it passed.
            val want = minOf(buffer.size.toLong(), limit + 1L - total).toInt()
            if (want <= 0) return null
            val count = input.read(buffer, 0, want)
            if (count < 0) break
            total += count
            if (total > limit) return null
            out.write(buffer, 0, count)
        }
        return out.toByteArray()
    }

    /**
     * A file name that is safe to put in the app's cache for a share: no folders (a name such as
     * `../../x` stays `x`), no control characters, no leading dots, at most 120 characters with the
     * extension kept. A name with nothing left is `lukitas`.
     */
    fun safeName(name: String): String {
        val leaf = name.substringAfterLast('/').substringAfterLast('\\')
        val cleaned = leaf.filter { !it.isISOControl() }.trim().trimStart('.').trim()
        if (cleaned.isEmpty()) return FALLBACK_NAME
        if (cleaned.length <= MAX_NAME) return cleaned
        val dot = cleaned.lastIndexOf('.')
        val extension = if (dot > 0 && cleaned.length - dot <= 16) cleaned.substring(dot) else ""
        return cleaned.substring(0, MAX_NAME - extension.length) + extension
    }

    /** The MIME types a picker offers: those given, else anything. */
    fun mimeTypesOf(argument: Any?): List<String> {
        val given = (argument as? List<*>)?.filterIsInstance<String>()?.filter { it.isNotBlank() }.orEmpty()
        return given.ifEmpty { listOf("*/*") }
    }

    /** The size limit a call asked for, within what is sane. */
    fun limitOf(argument: Any?): Int {
        val asked = (argument as? Number)?.toLong() ?: return DEFAULT_LIMIT
        return when {
            asked <= 0 -> DEFAULT_LIMIT
            asked > MAX_LIMIT -> MAX_LIMIT
            else -> asked.toInt()
        }
    }
}
