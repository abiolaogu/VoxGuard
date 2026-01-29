package com.billyrinks.antimasking.presentation.common.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.billyrinks.antimasking.domain.model.NigerianMno

/**
 * Nigerian phone number text field with +234 prefix and MNO detection badge
 */
@Composable
fun NigerianPhoneTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    detectedMno: NigerianMno = NigerianMno.UNKNOWN,
    enabled: Boolean = true,
    isError: Boolean = false,
    errorMessage: String? = null
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = { newValue ->
                // Filter to only digits and limit length
                val filtered = newValue.filter { it.isDigit() }.take(11)
                onValueChange(filtered)
            },
            label = { Text(label) },
            placeholder = { Text("0803 XXX XXXX") },
            enabled = enabled,
            isError = isError,
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Phone
            ),
            leadingIcon = {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(start = 12.dp)
                ) {
                    // Nigerian flag emoji
                    Text(
                        text = "🇳🇬",
                        fontSize = 20.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "+234",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    VerticalDivider(
                        modifier = Modifier.height(24.dp),
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            },
            trailingIcon = {
                if (detectedMno != NigerianMno.UNKNOWN) {
                    MnoBadge(mno = detectedMno)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        )

        // Error message
        if (isError && errorMessage != null) {
            Text(
                text = errorMessage,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
            )
        }
    }
}

/**
 * MNO detection badge
 */
@Composable
fun MnoBadge(
    mno: NigerianMno,
    modifier: Modifier = Modifier
) {
    val backgroundColor = when (mno) {
        NigerianMno.MTN -> Color(0xFFFFCC00) // MTN Yellow
        NigerianMno.GLO -> Color(0xFF50B848) // Glo Green
        NigerianMno.AIRTEL -> Color(0xFFED1C24) // Airtel Red
        NigerianMno.NINE_MOBILE -> Color(0xFF006837) // 9mobile Green
        NigerianMno.UNKNOWN -> MaterialTheme.colorScheme.surfaceVariant
    }

    val textColor = when (mno) {
        NigerianMno.MTN -> Color.Black
        else -> Color.White
    }

    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(6.dp),
        modifier = modifier.padding(end = 12.dp)
    ) {
        Text(
            text = mno.displayName.split(" ").first(),
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = textColor
        )
    }
}

/**
 * Account number text field with bank validation
 */
@Composable
fun AccountNumberTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    bankName: String? = null,
    isVerifying: Boolean = false,
    isVerified: Boolean = false,
    enabled: Boolean = true
) {
    OutlinedTextField(
        value = value,
        onValueChange = { newValue ->
            val filtered = newValue.filter { it.isDigit() }.take(10)
            onValueChange(filtered)
        },
        label = { Text(label) },
        placeholder = { Text("0123456789") },
        enabled = enabled,
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Number
        ),
        supportingText = {
            if (bankName != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (isVerifying) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(12.dp),
                            strokeWidth = 1.dp
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Verifying...")
                    } else if (isVerified) {
                        Text(
                            text = "✓ $bankName",
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        },
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    )
}

/**
 * Amount input field with currency symbol
 */
@Composable
fun AmountTextField(
    value: String,
    onValueChange: (String) -> Unit,
    currencySymbol: String = "₦",
    label: String = "Amount",
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isError: Boolean = false
) {
    OutlinedTextField(
        value = value,
        onValueChange = { newValue ->
            // Allow only digits and one decimal point
            val filtered = newValue.filter { it.isDigit() || it == '.' }
            if (filtered.count { it == '.' } <= 1) {
                onValueChange(filtered)
            }
        },
        label = { Text(label) },
        enabled = enabled,
        isError = isError,
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Decimal
        ),
        prefix = {
            Text(
                text = currencySymbol,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        },
        textStyle = TextStyle(
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold
        ),
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    )
}
