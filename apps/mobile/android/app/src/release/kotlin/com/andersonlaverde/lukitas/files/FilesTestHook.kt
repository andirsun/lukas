package com.andersonlaverde.lukitas.files

import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The release build has no test hook: nothing can stand in for the picker. */
internal object FilesTestHook {
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean = false

    fun take(): Uri? = null

    fun takeSave(): Uri? = null
}
