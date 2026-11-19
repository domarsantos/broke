package app.minifocus.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import app.minifocus.domain.Mode
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import java.util.UUID

/** Dropdown to link a tag to a Mode (or none). Mirrors iOS `ModePickerField`. */
@Composable
fun ModePickerField(
    modes: List<Mode>,
    selectedModeId: UUID?,
    onSelect: (UUID?) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedName = modes.firstOrNull { it.id == selectedModeId }?.name ?: MiniCopy.modePickerNone

    Box {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true }
                .padding(vertical = MiniSpacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(selectedName, style = MaterialTheme.typography.bodyLarge, color = MiniColor.text, modifier = Modifier.weight(1f))
            Icon(Icons.Filled.ArrowDropDown, contentDescription = null, tint = MiniColor.muted)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text(MiniCopy.modePickerNone) },
                onClick = { onSelect(null); expanded = false },
            )
            modes.forEach { mode ->
                DropdownMenuItem(
                    text = { Text(mode.name) },
                    onClick = { onSelect(mode.id); expanded = false },
                )
            }
        }
    }
}
