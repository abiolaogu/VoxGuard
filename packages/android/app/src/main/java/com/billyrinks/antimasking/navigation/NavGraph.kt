package com.billyrinks.antimasking.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.billyrinks.antimasking.presentation.anti_masking.AntiMaskingScreen

/**
 * Navigation routes for the app
 */
object Routes {
    const val ANTI_MASKING = "anti_masking"
    const val VERIFICATION_DETAILS = "verification/{verificationId}"
    const val REMITTANCE = "remittance"
    const val REMITTANCE_SEND = "remittance/send"
    const val MARKETPLACE = "marketplace"
    const val MARKETPLACE_LISTING = "marketplace/listing/{listingId}"
    const val SETTINGS = "settings"

    fun verificationDetails(id: String) = "verification/$id"
    fun marketplaceListing(id: String) = "marketplace/listing/$id"
}

/**
 * Main navigation graph
 */
@Composable
fun NavGraph(
    navController: NavHostController,
    startDestination: String = Routes.ANTI_MASKING
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Anti-Masking feature
        composable(Routes.ANTI_MASKING) {
            AntiMaskingScreen(
                onNavigateToDetails = { verificationId ->
                    navController.navigate(Routes.verificationDetails(verificationId))
                }
            )
        }

        // Verification details
        composable(
            route = Routes.VERIFICATION_DETAILS,
            arguments = listOf(
                navArgument("verificationId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val verificationId = backStackEntry.arguments?.getString("verificationId") ?: ""
            // VerificationDetailsScreen(verificationId = verificationId)
        }

        // Remittance feature
        composable(Routes.REMITTANCE) {
            // RemittanceScreen()
        }

        composable(Routes.REMITTANCE_SEND) {
            // SendRemittanceScreen()
        }

        // Marketplace feature
        composable(Routes.MARKETPLACE) {
            // MarketplaceScreen()
        }

        composable(
            route = Routes.MARKETPLACE_LISTING,
            arguments = listOf(
                navArgument("listingId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val listingId = backStackEntry.arguments?.getString("listingId") ?: ""
            // ListingDetailsScreen(listingId = listingId)
        }

        // Settings
        composable(Routes.SETTINGS) {
            // SettingsScreen()
        }
    }
}
