package com.andersonlaverde.lukitas.haptics

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The phone's motor (lib/feedback/feedback_platform.dart), on the `lukitas/haptics` method channel.
 *
 * `vibrate({waveform, primitives})` → Boolean (a motor played it) plays the feel of an event (see [HapticSpec]). On Android 11
 * (API 30) and up, when the motor supports every primitive asked for (or its fallback), it plays a
 * `VibrationEffect.Composition` (a crisp click or tick, or the deeper thud and low tick of
 * Android 12, played as a click and a tick by a motor without them); otherwise, and on older phones, the
 * waveform: the web's own pattern. A phone with no motor, or with vibration turned off, does
 * nothing, and no call fails because of it. The VIBRATE permission is a normal one, granted at
 * install.
 */
class HapticsChannel(context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val methods = MethodChannel(messenger, "lukitas/haptics")
    private val vibrator: Vibrator? = vibratorOf(context)

    init {
        methods.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "vibrate" -> {
                val spec = HapticSpec.parse(call.arguments)
                if (spec == null) {
                    result.error("bad-pattern", "Nothing sound to play", null)
                    return
                }
                try {
                    result.success(play(spec))
                } catch (e: RuntimeException) {
                    // A motor that refuses (a security exception, say) is no reason to fail a save.
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
    }

    /** Whether the phone has a motor and was asked to play. */
    private fun play(spec: HapticSpec): Boolean {
        val motor = vibrator?.takeIf { it.hasVibrator() } ?: return false
        val effect = composition(motor, spec) ?: VibrationEffect.createWaveform(spec.timings(), -1)
        vibrate(motor, effect)
        return true
    }

    /** The composition for [spec], or null when this phone cannot play it (API below 30, say). */
    private fun composition(motor: Vibrator, spec: HapticSpec): VibrationEffect? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || spec.primitives.isEmpty()) return null
        // Each step as itself, or as its fallback (a `thud` as a `click`) where the motor lacks it.
        val ids = spec.primitives.map { step ->
            val own = primitiveId(step.name)
            when {
                motor.areAllPrimitivesSupported(own) -> own
                step.fallback != null -> primitiveId(step.fallback!!)
                else -> return null
            }
        }
        if (!motor.areAllPrimitivesSupported(*ids.toIntArray())) return null
        val composition = VibrationEffect.startComposition()
        spec.primitives.forEachIndexed { index, step ->
            composition.addPrimitive(ids[index], step.scale, step.delayMs)
        }
        return composition.compose()
    }

    // THUD and LOW_TICK are API 31 constants, inlined at compile time: on Android 11 the motor
    // simply reports them unsupported, and the fallback plays.
    private fun primitiveId(name: String): Int = when (name) {
        "click" -> VibrationEffect.Composition.PRIMITIVE_CLICK
        "thud" -> VibrationEffect.Composition.PRIMITIVE_THUD
        "lowTick" -> VibrationEffect.Composition.PRIMITIVE_LOW_TICK
        else -> VibrationEffect.Composition.PRIMITIVE_TICK
    }

    // A touch on Android 13+ (it follows the phone's "touch feedback" setting, as a keyboard's tick
    // does); below, the sonification usage, which that setting does not gate.
    @Suppress("DEPRECATION")
    private fun vibrate(motor: Vibrator, effect: VibrationEffect) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            motor.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            motor.vibrate(
                effect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
    }

    private companion object {
        @Suppress("DEPRECATION")
        fun vibratorOf(context: Context): Vibrator? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
    }
}
