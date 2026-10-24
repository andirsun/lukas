package com.andersonlaverde.lukitas.tile

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.andersonlaverde.lukitas.R
import com.andersonlaverde.lukitas.launch.LaunchLinks

/**
 * The Quick Settings tile (spec section 7.1): a mic that does what the widget's 🎤 does, quick
 * capture listening (`lukitas://capture`). On a locked phone it asks to unlock first: the app
 * holds the person's money.
 */
class CaptureTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = getString(R.string.tile_capture)
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) unlockAndRun { openCapture() } else openCapture()
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openCapture() {
        val intent = LaunchLinks.intent(this, LaunchLinks.CAPTURE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
