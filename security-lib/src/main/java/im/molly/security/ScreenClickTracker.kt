package im.molly.security

import android.util.Log
import android.view.MotionEvent
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/**
 * Tracks screen click/touch coordinates for embedding in noise generation.
 * Implements "bury them with bullshit" strategy by tracking all user interactions.
 */
object ScreenClickTracker {
    private const val TAG = "ScreenClickTracker"

    // Store last click coordinates (thread-safe)
    private val lastX = AtomicInteger(0)
    private val lastY = AtomicInteger(0)
    private val lastClickTime = AtomicReference<Long>(0L)

    // Track if tracking is enabled
    @Volatile
    private var isTrackingEnabled = true

    /**
     * Process a touch/click event and store coordinates
     * Call this from Activity.onTouchEvent() or View.onTouchEvent()
     */
    fun onTouchEvent(event: MotionEvent): Boolean {
        if (!isTrackingEnabled) return false

        when (event.action) {
            MotionEvent.ACTION_DOWN,
            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_MOVE -> {
                val x = event.x.toInt()
                val y = event.y.toInt()
                lastX.set(x)
                lastY.set(y)
                lastClickTime.set(System.currentTimeMillis())

                Log.d(TAG, "Screen click tracked: x=$x, y=$y")
            }
        }

        return false  // Don't consume the event
    }

    /**
     * Get the last tracked screen coordinates
     * @return Pair of (x, y) coordinates, or (0, 0) if no clicks tracked
     */
    fun getLastCoordinates(): Pair<Int, Int> {
        return Pair(lastX.get(), lastY.get())
    }

    /**
     * Get the last click time
     */
    fun getLastClickTime(): Long {
        return lastClickTime.get()
    }

    /**
     * Enable or disable click tracking
     */
    fun setTrackingEnabled(enabled: Boolean) {
        isTrackingEnabled = enabled
        Log.d(TAG, "Screen click tracking ${if (enabled) "enabled" else "disabled"}")
    }

    /**
     * Check if tracking is enabled
     */
    fun isTrackingEnabled(): Boolean = isTrackingEnabled

    /**
     * Reset tracked coordinates
     */
    fun reset() {
        lastX.set(0)
        lastY.set(0)
        lastClickTime.set(0L)
        Log.d(TAG, "Screen click coordinates reset")
    }
}

