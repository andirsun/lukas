package com.andersonlaverde.lukitas.voice

import java.io.File
import java.util.zip.ZipInputStream

/** Unzips a downloaded voice model (VoiceChannel.kt). Plain JVM code, so it has a unit test. */
object ZipExtract {
    /** Unzips [zip] into [into], refusing any entry that would land outside it (zip slip). */
    fun unzip(zip: File, into: File) {
        val root = into.canonicalFile
        root.mkdirs()
        ZipInputStream(zip.inputStream().buffered()).use { stream ->
            while (true) {
                val entry = stream.nextEntry ?: break
                val target = File(root, entry.name).canonicalFile
                if (!target.path.startsWith(root.path + File.separator)) {
                    throw SecurityException("Zip entry outside the target: ${entry.name}")
                }
                if (entry.isDirectory) {
                    target.mkdirs()
                } else {
                    target.parentFile?.mkdirs()
                    target.outputStream().use { stream.copyTo(it) }
                }
            }
        }
    }
}
