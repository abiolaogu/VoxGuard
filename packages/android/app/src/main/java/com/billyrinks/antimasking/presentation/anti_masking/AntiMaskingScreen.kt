package com.billyrinks.antimasking.presentation.anti_masking

import android.os.VibrationEffect
import android.os.Vibrator
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.getSystemService
import androidx.hilt.navigation.compose.hiltViewModel
import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.model.NigerianMno
import com.billyrinks.antimasking.domain.model.RiskLevel
import com.billyrinks.antimasking.presentation.common.components.NigerianPhoneTextField
import org.orbitmvi.orbit.compose.collectAsState
import org.orbitmvi.orbit.compose.collectSideEffect
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

/**
 * Anti-Masking Screen with Jetpack Compose Material3
 */
@Composable
fun AntiMaskingScreen(
    viewModel: AntiMaskingViewModel = hiltViewModel(),
    onNavigateToDetails: (String) -> Unit = {},
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
) {
    val state by viewModel.collectAsState()
    val context = LocalContext.current
    var showAlertDialog by remember { mutableStateOf<CallVerification?>(null) }

    // Collect side effects
    viewModel.collectSideEffect { sideEffect ->
        when (sideEffect) {
            is AntiMaskingSideEffect.ShowMaskingAlert -> {
                showAlertDialog = sideEffect.verification
            }
            is AntiMaskingSideEffect.ShowFraudAlert -> {
                snackbarHostState.showSnackbar(
                    message = sideEffect.alert.title,
                    actionLabel = "View",
                    duration = SnackbarDuration.Long
                )
            }
            is AntiMaskingSideEffect.ShowMessage -> {
                snackbarHostState.showSnackbar(
                    message = sideEffect.message,
                    duration = if (sideEffect.isError) SnackbarDuration.Long else SnackbarDuration.Short
                )
            }
            is AntiMaskingSideEffect.NavigateToVerificationDetails -> {
                onNavigateToDetails(sideEffect.verificationId)
            }
            AntiMaskingSideEffect.TriggerHapticFeedback -> {
                context.getSystemService<Vibrator>()?.vibrate(
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 200, 100, 200),
                        -1
                    )
                )
            }
            AntiMaskingSideEffect.PlayMaskingAlertSound -> {
                // Play alert sound
            }
            AntiMaskingSideEffect.ReportSubmittedSuccessfully -> {
                snackbarHostState.showSnackbar(
                    message = "Report submitted to NCC",
                    duration = SnackbarDuration.Short
                )
            }
        }
    }

    // Show masking alert dialog
    showAlertDialog?.let { verification ->
        MaskingAlertDialog(
            verification = verification,
            onDismiss = { showAlertDialog = null },
            onReport = {
                viewModel.reportToNCC(verification.id)
                showAlertDialog = null
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            item {
                AntiMaskingHeader()
            }

            // Verification Form Card
            item {
                VerificationFormCard(
                    callerNumber = state.callerNumber,
                    calleeNumber = state.calleeNumber,
                    callerMno = state.callerMno,
                    calleeMno = state.calleeMno,
                    isVerifying = state.isVerifying,
                    canVerify = state.canVerify,
                    onCallerNumberChanged = viewModel::onCallerNumberChanged,
                    onCalleeNumberChanged = viewModel::onCalleeNumberChanged,
                    onVerify = viewModel::verifyCall
                )
            }

            // Latest Verification Result
            state.latestVerification?.let { verification ->
                item {
                    LatestVerificationCard(verification = verification)
                }
            }

            // Fraud Alerts Section
            if (state.fraudAlerts.isNotEmpty()) {
                item {
                    FraudAlertsBanner(
                        alertCount = state.unacknowledgedAlertCount,
                        onClick = { /* Navigate to alerts */ }
                    )
                }
            }

            // History Section Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Verification History",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    FilterChip(
                        selected = state.showMaskingDetectedOnly,
                        onClick = { viewModel.toggleMaskingFilter() },
                        label = { Text("Masking Only") },
                        leadingIcon = {
                            if (state.showMaskingDetectedOnly) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    )
                }
            }

            // Loading indicator for history
            if (state.isLoadingHistory) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(32.dp))
                    }
                }
            }

            // Verification History List
            items(
                items = state.verificationHistory,
                key = { it.id }
            ) { verification ->
                VerificationHistoryItem(
                    verification = verification,
                    onClick = { viewModel.onVerificationClicked(verification.id) }
                )
            }

            // Empty state
            if (!state.isLoadingHistory && state.verificationHistory.isEmpty()) {
                item {
                    EmptyHistoryState()
                }
            }
        }
    }
}

@Composable
private fun AntiMaskingHeader() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Security,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(32.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(
                text = "Call Verification",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Detect CLI masking and protect your calls 🇳🇬",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun VerificationFormCard(
    callerNumber: String,
    calleeNumber: String,
    callerMno: NigerianMno,
    calleeMno: NigerianMno,
    isVerifying: Boolean,
    canVerify: Boolean,
    onCallerNumberChanged: (String) -> Unit,
    onCalleeNumberChanged: (String) -> Unit,
    onVerify: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Caller number input
            NigerianPhoneTextField(
                value = callerNumber,
                onValueChange = onCallerNumberChanged,
                label = "Caller Number",
                detectedMno = callerMno,
                enabled = !isVerifying
            )

            // Callee number input
            NigerianPhoneTextField(
                value = calleeNumber,
                onValueChange = onCalleeNumberChanged,
                label = "Callee Number",
                detectedMno = calleeMno,
                enabled = !isVerifying
            )

            // Verify button
            Button(
                onClick = onVerify,
                enabled = canVerify,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (isVerifying) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(22.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Verifying...")
                } else {
                    Icon(
                        imageVector = Icons.Default.Verified,
                        contentDescription = null
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Verify Call")
                }
            }
        }
    }
}

@Composable
private fun LatestVerificationCard(verification: CallVerification) {
    val backgroundColor = when {
        verification.maskingDetected -> MaterialTheme.colorScheme.errorContainer
        verification.confidenceScore < 0.3 -> MaterialTheme.colorScheme.primaryContainer
        else -> MaterialTheme.colorScheme.secondaryContainer
    }

    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse"
    )

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = backgroundColor)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(if (verification.maskingDetected) 48.dp * pulseScale else 48.dp)
                        .clip(CircleShape)
                        .background(
                            if (verification.maskingDetected)
                                MaterialTheme.colorScheme.error
                            else
                                MaterialTheme.colorScheme.primary
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (verification.maskingDetected)
                            Icons.Default.Warning
                        else
                            Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(28.dp)
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = if (verification.maskingDetected)
                            "Masking Detected!"
                        else
                            "Verification Complete",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (verification.maskingDetected)
                            MaterialTheme.colorScheme.error
                        else
                            MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Confidence: ${(verification.confidenceScore * 100).toInt()}%",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }

                RiskLevelBadge(riskLevel = verification.riskLevel)
            }

            if (verification.maskingDetected) {
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = { /* Block */ },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.Block, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Block")
                    }
                    Button(
                        onClick = { /* Report */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(Icons.Default.Report, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Report")
                    }
                }
            }
        }
    }
}

@Composable
private fun RiskLevelBadge(riskLevel: RiskLevel) {
    val (backgroundColor, textColor) = when (riskLevel) {
        RiskLevel.CRITICAL -> MaterialTheme.colorScheme.error to MaterialTheme.colorScheme.onError
        RiskLevel.HIGH -> MaterialTheme.colorScheme.errorContainer to MaterialTheme.colorScheme.onErrorContainer
        RiskLevel.MEDIUM -> MaterialTheme.colorScheme.tertiaryContainer to MaterialTheme.colorScheme.onTertiaryContainer
        RiskLevel.LOW -> MaterialTheme.colorScheme.primaryContainer to MaterialTheme.colorScheme.onPrimaryContainer
    }

    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            text = riskLevel.name,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = textColor
        )
    }
}

@Composable
private fun FraudAlertsBanner(
    alertCount: Int,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Badge(
                containerColor = MaterialTheme.colorScheme.error
            ) {
                Text(alertCount.toString())
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Fraud Alerts",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "$alertCount unacknowledged alerts",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View alerts"
            )
        }
    }
}

@Composable
private fun VerificationHistoryItem(
    verification: CallVerification,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status icon
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        if (verification.maskingDetected)
                            MaterialTheme.colorScheme.errorContainer
                        else
                            MaterialTheme.colorScheme.primaryContainer
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (verification.maskingDetected)
                        Icons.Outlined.Warning
                    else
                        Icons.Outlined.Verified,
                    contentDescription = null,
                    tint = if (verification.maskingDetected)
                        MaterialTheme.colorScheme.error
                    else
                        MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = verification.callerNumber,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = verification.verifiedAt.format(
                        java.time.format.DateTimeFormatter.ofLocalizedDateTime(
                            java.time.format.FormatStyle.SHORT
                        )
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            RiskLevelBadge(riskLevel = verification.riskLevel)
        }
    }
}

@Composable
private fun EmptyHistoryState() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Outlined.History,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "No verifications yet",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Verify a call to see history",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun MaskingAlertDialog(
    verification: CallVerification,
    onDismiss: () -> Unit,
    onReport: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(48.dp)
            )
        },
        title = {
            Text(
                text = "CLI Masking Detected!",
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center
            )
        },
        text = {
            Column {
                Text(
                    text = "Suspicious activity detected on this call.",
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(16.dp))
                InfoRow("Caller", verification.callerNumber)
                InfoRow("Confidence", "${(verification.confidenceScore * 100).toInt()}%")
                verification.detectedMno?.let {
                    InfoRow("Network", it)
                }
            }
        },
        confirmButton = {
            Button(
                onClick = onReport,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Report to NCC")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Dismiss")
            }
        }
    )
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}
