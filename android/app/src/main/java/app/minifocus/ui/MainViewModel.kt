package app.minifocus.ui

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import app.minifocus.AppContainer
import app.minifocus.domain.FocusSession
import app.minifocus.domain.FocusTag
import app.minifocus.domain.Mode
import app.minifocus.focus.FocusController
import app.minifocus.focus.FocusOutcome
import app.minifocus.nfc.ScannedTag
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

/** Snapshot of the active focus state exposed to the UI. */
data class FocusSnapshot(
    val isActive: Boolean = false,
    val activeMode: Mode? = null,
    val activeSession: FocusSession? = null,
)

/**
 * Consolidates the behaviour of iOS' `ModeStore`, `TagStore` and the mutating
 * parts of `AppEnvironment` into a single Android ViewModel. It is the only
 * object the Compose screens talk to for reads and writes; activation logic
 * still lives entirely in [FocusController].
 */
class MainViewModel(
    app: Application,
    private val container: AppContainer,
) : AndroidViewModel(app) {

    private val controller: FocusController = container.focusController
    private val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private val _modes = MutableStateFlow<List<Mode>>(emptyList())
    val modes: StateFlow<List<Mode>> = _modes.asStateFlow()

    private val _tags = MutableStateFlow<List<FocusTag>>(emptyList())
    val tags: StateFlow<List<FocusTag>> = _tags.asStateFlow()

    private val _selectedModeId = MutableStateFlow(readSelectedModeId())
    val selectedModeId: StateFlow<UUID?> = _selectedModeId.asStateFlow()

    private val _focus = MutableStateFlow(FocusSnapshot())
    val focus: StateFlow<FocusSnapshot> = _focus.asStateFlow()

    private val _isAuthorized = MutableStateFlow(container.blocker.isAuthorized)
    val isAuthorized: StateFlow<Boolean> = _isAuthorized.asStateFlow()

    init {
        viewModelScope.launch {
            loadModesAndTags()
            controller.recover()
            refreshFocus()
        }
    }

    /** The Mode used when a tag has no link, or when starting manually. */
    private val effectiveSelectedModeId: UUID?
        get() = _selectedModeId.value?.takeIf { id -> _modes.value.any { it.id == id } }
            ?: _modes.value.firstOrNull()?.id

    val selectedMode: Mode?
        get() = _modes.value.firstOrNull { it.id == effectiveSelectedModeId }

    // MARK: - Loading

    private suspend fun loadModesAndTags() {
        var list = container.modeRepository.fetchAll()
        if (list.isEmpty()) {
            container.modeRepository.create(Mode(name = MiniCopy.defaultModeName))
            list = container.modeRepository.fetchAll()
        }
        _modes.value = list
        if (_selectedModeId.value == null || list.none { it.id == _selectedModeId.value }) {
            setSelectedModeId(list.firstOrNull()?.id)
        }
        _tags.value = container.tagRepository.fetchAll()
    }

    private fun refreshFocus() {
        _focus.value = FocusSnapshot(
            isActive = controller.isActive,
            activeMode = controller.activeMode,
            activeSession = controller.activeSession,
        )
    }

    fun refreshAuthorization() {
        _isAuthorized.value = container.blocker.isAuthorized
    }

    fun openAuthorizationSettings() {
        container.blocker.openAuthorizationSettings()
    }

    // MARK: - Mode selection

    fun selectMode(id: UUID) {
        if (_modes.value.none { it.id == id }) return
        setSelectedModeId(id)
    }

    private fun setSelectedModeId(id: UUID?) {
        _selectedModeId.value = id
        prefs.edit().putString(KEY_SELECTED_MODE, id?.toString()).apply()
    }

    private fun readSelectedModeId(): UUID? =
        prefs.getString(KEY_SELECTED_MODE, null)?.let { runCatching { UUID.fromString(it) }.getOrNull() }

    // MARK: - Mode CRUD

    fun addMode(name: String, icon: String, packages: Set<String>, onDone: (Mode) -> Unit = {}) {
        viewModelScope.launch {
            val mode = Mode(name = name, icon = icon, packages = packages)
            container.modeRepository.create(mode)
            _modes.value = container.modeRepository.fetchAll()
            setSelectedModeId(mode.id)
            onDone(mode)
        }
    }

    fun updateMode(id: UUID, name: String, icon: String, packages: Set<String>, onDone: () -> Unit = {}) {
        viewModelScope.launch {
            val existing = container.modeRepository.fetch(id) ?: return@launch
            val updated = existing.copy(
                name = name,
                icon = icon,
                packages = packages,
                updatedAt = java.time.Instant.now(),
            )
            container.modeRepository.update(updated)
            _modes.value = container.modeRepository.fetchAll()
            // Reapply limiting if the edited Mode is the one currently active.
            if (controller.activeMode?.id == id) {
                container.blocker.apply(updated)
            }
            onDone()
        }
    }

    /** Delete a Mode safely. Returns false if it is the active Mode. */
    fun deleteMode(id: UUID, onResult: (Boolean) -> Unit = {}) {
        viewModelScope.launch {
            if (controller.activeMode?.id == id) {
                onResult(false)
                return@launch
            }
            container.tagRepository.unlinkMode(id)
            container.modeRepository.delete(id)
            loadModesAndTags()
            onResult(true)
        }
    }

    // MARK: - Tag CRUD

    fun registerTag(
        hardwareIdentifier: String?,
        name: String,
        linkedModeId: UUID?,
        onDone: () -> Unit = {},
        onError: (String) -> Unit = {},
    ) {
        viewModelScope.launch {
            try {
                container.tagRepository.register(
                    FocusTag(hardwareIdentifier = hardwareIdentifier, name = name, linkedModeId = linkedModeId)
                )
                _tags.value = container.tagRepository.fetchAll()
                onDone()
            } catch (e: Exception) {
                onError(e.message ?: "")
            }
        }
    }

    fun renameTag(tag: FocusTag, name: String) {
        viewModelScope.launch {
            container.tagRepository.update(tag.copy(name = name))
            _tags.value = container.tagRepository.fetchAll()
        }
    }

    fun setTagMode(tag: FocusTag, modeId: UUID?) {
        viewModelScope.launch {
            container.tagRepository.update(tag.copy(linkedModeId = modeId))
            _tags.value = container.tagRepository.fetchAll()
        }
    }

    fun deleteTag(id: UUID, onDone: () -> Unit = {}) {
        viewModelScope.launch {
            container.tagRepository.delete(id)
            _tags.value = container.tagRepository.fetchAll()
            onDone()
        }
    }

    fun tag(id: UUID): FocusTag? = _tags.value.firstOrNull { it.id == id }

    fun mode(id: UUID?): Mode? = id?.let { m -> _modes.value.firstOrNull { it.id == m } }

    // MARK: - Focus actions

    suspend fun handleScan(scanned: ScannedTag): FocusOutcome {
        val outcome = controller.handleScan(scanned, fallbackModeId = effectiveSelectedModeId)
        refreshFocus()
        return outcome
    }

    /** Start focus without a tag. Returns false when no Mode is available. */
    suspend fun startWithoutTag(): Boolean {
        val modeId = effectiveSelectedModeId ?: return false
        controller.startManual(modeId)
        refreshFocus()
        return true
    }

    private companion object {
        const val PREFS = "mini_focus_prefs"
        const val KEY_SELECTED_MODE = "selected_mode_id"
    }

    class Factory(
        private val app: Application,
        private val container: AppContainer,
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
            return MainViewModel(app, container) as T
        }
    }
}
