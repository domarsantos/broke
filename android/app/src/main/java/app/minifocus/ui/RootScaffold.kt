package app.minifocus.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.Nfc
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import app.minifocus.ui.screens.ModeFormScreen
import app.minifocus.ui.screens.ModesScreen
import app.minifocus.ui.screens.TagDetailScreen
import app.minifocus.ui.screens.TagPairingScreen
import app.minifocus.ui.screens.TagsScreen
import app.minifocus.ui.screens.TodayScreen
import app.minifocus.ui.theme.MiniColor
import java.util.UUID

private sealed class Tab(val route: String, val label: String, val icon: ImageVector) {
    data object Today : Tab("today", MiniCopy.navToday, Icons.Filled.Home)
    data object Modes : Tab("modes", MiniCopy.navModes, Icons.Filled.Layers)
    data object Tags : Tab("tags", MiniCopy.navTag, Icons.Filled.Nfc)
}

private val tabs = listOf(Tab.Today, Tab.Modes, Tab.Tags)
private val tabRoutes = tabs.map { it.route }.toSet()

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RootScaffold(viewModel: MainViewModel) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBars = currentRoute in tabRoutes

    val title = when (currentRoute) {
        Tab.Modes.route -> MiniCopy.modesTitle
        Tab.Tags.route -> MiniCopy.tagsTitle
        else -> MiniCopy.appName
    }

    Scaffold(
        containerColor = MiniColor.background,
        topBar = {
            if (showBars) {
                TopAppBar(
                    title = { Text(title) },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MiniColor.background,
                        titleContentColor = MiniColor.text,
                    ),
                )
            }
        },
        bottomBar = {
            if (showBars) {
                NavigationBar(containerColor = MiniColor.surface) {
                    val destination = backStackEntry?.destination
                    tabs.forEach { tab ->
                        val selected = destination?.hierarchy?.any { it.route == tab.route } == true
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(tab.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(tab.icon, contentDescription = null) },
                            label = { Text(tab.label) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = MiniColor.primary,
                                selectedTextColor = MiniColor.primary,
                                indicatorColor = MiniColor.sage,
                                unselectedIconColor = MiniColor.muted,
                                unselectedTextColor = MiniColor.muted,
                            ),
                        )
                    }
                }
            }
        },
    ) { inner ->
        NavHost(
            navController = navController,
            startDestination = Tab.Today.route,
            modifier = Modifier.padding(inner),
        ) {
            composable(Tab.Today.route) {
                TodayScreen(
                    viewModel = viewModel,
                    onPairNeeded = { scanned ->
                        navController.navigate("tagPairing?uid=${scanned.hardwareIdentifier}")
                    },
                )
            }
            composable(Tab.Modes.route) {
                ModesScreen(
                    viewModel = viewModel,
                    onNewMode = { navController.navigate("modeForm") },
                    onEditMode = { id -> navController.navigate("modeForm?modeId=$id") },
                )
            }
            composable(Tab.Tags.route) {
                TagsScreen(
                    viewModel = viewModel,
                    onAddTag = { navController.navigate("tagPairing") },
                    onOpenTag = { id -> navController.navigate("tagDetail/$id") },
                )
            }
            composable(
                route = "modeForm?modeId={modeId}",
                arguments = listOf(androidx.navigation.navArgument("modeId") {
                    nullable = true
                    defaultValue = null
                    type = androidx.navigation.NavType.StringType
                }),
            ) { entry ->
                val modeId = entry.arguments?.getString("modeId")?.let { runCatching { UUID.fromString(it) }.getOrNull() }
                ModeFormScreen(viewModel = viewModel, modeId = modeId, onClose = { navController.popBackStack() })
            }
            composable(
                route = "tagPairing?uid={uid}",
                arguments = listOf(androidx.navigation.navArgument("uid") {
                    nullable = true
                    defaultValue = null
                    type = androidx.navigation.NavType.StringType
                }),
            ) { entry ->
                val uid = entry.arguments?.getString("uid")
                TagPairingScreen(viewModel = viewModel, prefilledUid = uid, onClose = { navController.popBackStack() })
            }
            composable("tagDetail/{tagId}") { entry ->
                val tagId = entry.arguments?.getString("tagId")?.let { runCatching { UUID.fromString(it) }.getOrNull() }
                if (tagId != null) {
                    TagDetailScreen(viewModel = viewModel, tagId = tagId, onClose = { navController.popBackStack() })
                }
            }
        }
    }
}
