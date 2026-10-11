package com.example.farmestates_ai_dashbaord

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], application = Application::class)
class AndroidNotificationPermissionTest {
    private lateinit var activity: Activity
    private lateinit var permission: AndroidNotificationPermission
    private val prefs get() = activity.getSharedPreferences("message_notifications", Context.MODE_PRIVATE)

    @Before fun setup() {
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        prefs.edit().clear().commit()
        shadowOf(RuntimeEnvironment.getApplication()).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
        permission = AndroidNotificationPermission(activity)
    }

    @Test fun firstLaunchRequestsWithoutRequiringLoginAndWaitsForChoice() {
        var completed = false
        permission.request { completed = true }
        assertFalse(completed)
        assertFalse(prefs.getBoolean("asked", false))
        val request = shadowOf(activity).lastRequestedPermission
        assertEquals(AndroidNotificationPermission.REQUEST_CODE, request.requestCode)
        assertArrayEquals(arrayOf(Manifest.permission.POST_NOTIFICATIONS), request.requestedPermissions)
    }

    @Test fun grantingPermissionCompletesAllPendingRequestsAndPersistsChoice() {
        val results = mutableListOf<Boolean>()
        permission.request { results.add(it) }
        permission.request { results.add(it) }
        assertTrue(results.isEmpty())
        shadowOf(RuntimeEnvironment.getApplication()).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        permission.onResult(AndroidNotificationPermission.REQUEST_CODE, intArrayOf(PackageManager.PERMISSION_GRANTED))
        assertEquals(listOf(true, true), results)
        assertTrue(prefs.getBoolean("asked", false))
    }

    @Test fun denialCompletesFalseAndDoesNotAskAgainOnNextLaunch() {
        val results = mutableListOf<Boolean>()
        permission.request { results.add(it) }
        permission.onResult(AndroidNotificationPermission.REQUEST_CODE, intArrayOf(PackageManager.PERMISSION_DENIED))
        AndroidNotificationPermission(activity).request { results.add(it) }
        assertEquals(listOf(false, false), results)
        assertTrue(prefs.getBoolean("asked", false))
    }

    @Test fun alreadyGrantedDoesNotOpenAnotherPrompt() {
        shadowOf(RuntimeEnvironment.getApplication()).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        var result: Boolean? = null
        permission.request { result = it }
        assertEquals(true, result)
        assertNull(shadowOf(activity).lastRequestedPermission)
    }

    @Test fun dismissedPromptCanBeOfferedOnAFutureLaunch() {
        var result: Boolean? = null
        permission.request { result = it }
        permission.onResult(AndroidNotificationPermission.REQUEST_CODE, intArrayOf())
        assertEquals(false, result)
        assertFalse(prefs.getBoolean("asked", false))
        result = null
        AndroidNotificationPermission(activity).request { result = it }
        assertNull(result)
    }

    @Test fun unrelatedPermissionCallbackDoesNotReleaseStartup() {
        var result: Boolean? = null
        permission.request { result = it }
        permission.onResult(7, intArrayOf(PackageManager.PERMISSION_GRANTED))
        assertNull(result)
        permission.dispose()
        assertEquals(false, result)
    }

    @Test @Config(sdk = [31]) fun olderAndroidDoesNotRequestRuntimePermission() {
        var result: Boolean? = null
        permission.request { result = it }
        assertEquals(true, result)
        assertNull(shadowOf(activity).lastRequestedPermission)
    }
}
