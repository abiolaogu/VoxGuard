package com.acm.android.features.fraud.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.acm.android.features.fraud.viewmodel.FraudDashboardViewModel
import com.acm.android.features.fraud.viewmodel.FraudSummary

/**
 * Fraud Prevention Dashboard Screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FraudDashboardScreen(
    viewModel: FraudDashboardViewModel = hiltViewModel(),
    onNavigateToCli: () -> Unit = {},
    onNavigateToIrsf: () -> Unit = {},
    onNavigateToWangiri: () -> Unit = {},
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Fraud Prevention") },
                actions = {
                    IconButton(onClick = { viewModel.refresh() }) {
                        Icon(Icons.Default.Refresh, "Refresh")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Summary Cards
            item {
                Text(
                    text = "Fraud Summary",
                    style = MaterialTheme.typography.headlineSmall
                )
            }

            item {
                when (val state = uiState.summary) {
                    is FraudSummaryState.Loading -> {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                    is FraudSummaryState.Success -> {
                        FraudSummaryCards(summary = state.data)
                    }
                    is FraudSummaryState.Error -> {
                        Text("Error: ${state.message}", color = MaterialTheme.colorScheme.error)
                    }
                }
            }

            // Revenue Protected
            item {
                RevenueProtectedCard(
                    amount = uiState.summary.let {
                        if (it is FraudSummaryState.Success) it.data.totalRevenueProtected else 0.0
                    }
                )
            }

            // Quick Actions
            item {
                Text(
                    text = "Quick Actions",
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }

            item { ActionCard("CLI Verifications", "View spoofing detections", Icons.Default.Security, onNavigateToCli) }
            item { ActionCard("IRSF Incidents", "International revenue share fraud", Icons.Default.Language, onNavigateToIrsf) }
            item { ActionCard("Wangiri Detection", "One-ring fraud tracking", Icons.Default.PhoneMissed, onNavigateToWangiri) }
        }
    }
}

@Composable
fun FraudSummaryCards(summary: FraudSummary) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            SummaryCard(
                modifier = Modifier.weight(1f),
                title = "CLI Spoofing",
                count = summary.cliSpoofingCount,
                icon = Icons.Default.Security,
                color = Color(0xFFCF1322)
            )
            SummaryCard(
                modifier = Modifier.weight(1f),
                title = "IRSF",
                count = summary.irsfCount,
                icon = Icons.Default.Language,
                color = Color(0xFFFA541C)
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            SummaryCard(
                modifier = Modifier.weight(1f),
                title = "Wangiri",
                count = summary.wangiriCount,
                icon = Icons.Default.PhoneMissed,
                color = Color(0xFF1890FF)
            )
            SummaryCard(
                modifier = Modifier.weight(1f),
                title = "Callback",
                count = summary.callbackFraudCount,
                icon = Icons.Default.PhoneCallback,
                color = Color(0xFF722ED1)
            )
        }
    }
}

@Composable
fun SummaryCard(
    modifier: Modifier = Modifier,
    title: String,
    count: Int,
    icon: ImageVector,
    color: Color
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(icon, title, tint = color)
                Surface(
                    color = color.copy(alpha = 0.1f),
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = count.toString(),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        color = color,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(title, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
fun RevenueProtectedCard(amount: Double) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Shield,
                "Protected",
                modifier = Modifier.size(40.dp),
                tint = Color(0xFF2E7D32)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text("Revenue Protected", style = MaterialTheme.typography.bodyMedium)
                Text(
                    text = "₦${String.format("%,.0f", amount)}",
                    style = MaterialTheme.typography.headlineMedium,
                    color = Color(0xFF2E7D32),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit
) {
    Card(onClick = onClick) {
        ListItem(
            leadingContent = {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = MaterialTheme.shapes.medium
                ) {
                    Icon(
                        icon,
                        title,
                        modifier = Modifier.padding(8.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            },
            headlineContent = { Text(title) },
            supportingContent = { Text(subtitle) },
            trailingContent = { Icon(Icons.Default.ChevronRight, "Navigate") }
        )
    }
}

// UI State
sealed class FraudSummaryState {
    object Loading : FraudSummaryState()
    data class Success(val data: FraudSummary) : FraudSummaryState()
    data class Error(val message: String) : FraudSummaryState()
}

data class FraudDashboardUiState(
    val summary: FraudSummaryState = FraudSummaryState.Loading
)
