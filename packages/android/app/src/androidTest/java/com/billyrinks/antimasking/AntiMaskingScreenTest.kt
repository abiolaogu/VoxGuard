package com.billyrinks.antimasking

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.billyrinks.antimasking.presentation.anti_masking.AntiMaskingScreen
import com.billyrinks.antimasking.presentation.theme.AntiMaskingTheme
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Instrumented tests for AntiMaskingScreen
 */
@HiltAndroidTest
class AntiMaskingScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createComposeRule()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun antiMaskingScreen_displaysHeader() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("Call Verification").assertIsDisplayed()
    }

    @Test
    fun antiMaskingScreen_displaysPhoneInputFields() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("Caller Number").assertIsDisplayed()
        composeRule.onNodeWithText("Callee Number").assertIsDisplayed()
    }

    @Test
    fun antiMaskingScreen_verifyButtonDisabledInitially() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("Verify Call").assertIsNotEnabled()
    }

    @Test
    fun antiMaskingScreen_verifyButtonEnabledWithValidNumbers() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        // Enter caller number
        composeRule.onNodeWithText("Caller Number")
            .performTextInput("08030001234")

        // Enter callee number  
        composeRule.onNodeWithText("Callee Number")
            .performTextInput("09010005678")

        // Verify button should be enabled
        composeRule.onNodeWithText("Verify Call").assertIsEnabled()
    }

    @Test
    fun antiMaskingScreen_showsEmptyHistoryState() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("No verifications yet").assertIsDisplayed()
    }

    @Test
    fun antiMaskingScreen_displaysHistoryHeader() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("Verification History").assertIsDisplayed()
    }

    @Test
    fun antiMaskingScreen_filterChipClickable() {
        composeRule.setContent {
            AntiMaskingTheme {
                AntiMaskingScreen()
            }
        }

        composeRule.onNodeWithText("Masking Only").assertIsDisplayed()
        composeRule.onNodeWithText("Masking Only").performClick()
    }
}
