package app.minifocus.block

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniFocusTheme
import app.minifocus.ui.theme.MiniSpacing

/**
 * Full-screen shield shown by [FocusAccessibilityService] when the user opens
 * an app that the active Mode limits. It states that focus is active and offers
 * a single, calm way out: return to the home screen.
 */
class BlockActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MiniFocusTheme {
                BlockScreen(onDismiss = ::goHome)
            }
        }
    }

    private fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
        finish()
    }
}

@Composable
private fun BlockScreen(onDismiss: () -> Unit) {
    Surface(modifier = Modifier.fillMaxSize(), color = MiniColor.primary) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(MiniSpacing.horizontal),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = MiniCopy.homeOnTitle,
                color = MiniColor.onPrimary,
                textAlign = TextAlign.Center,
                style = androidx.compose.material3.MaterialTheme.typography.headlineMedium,
            )
            Text(
                text = MiniCopy.blockBody,
                color = MiniColor.sage,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = MiniSpacing.md),
                style = androidx.compose.material3.MaterialTheme.typography.bodyLarge,
            )
            Button(
                onClick = onDismiss,
                modifier = Modifier.padding(top = MiniSpacing.xl),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MiniColor.onPrimary,
                    contentColor = MiniColor.primary,
                ),
            ) {
                Text(MiniCopy.blockGoHome, modifier = Modifier.padding(vertical = 4.dp))
            }
        }
    }
}
