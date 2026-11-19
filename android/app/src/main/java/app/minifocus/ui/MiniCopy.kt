package app.minifocus.ui

/**
 * Centralized user-facing copy for Mini Focus, in Brazilian Portuguese. Port of
 * `MiniFocus/Design/MiniCopy.swift`. Voice: calm, direct, trustworthy. Short
 * sentences, active voice, no punitive or infantilizing language.
 *
 * Where iOS talks about "Tempo de Uso" (Screen Time), Android uses the
 * accessibility permission, so a few strings were adapted to stay honest about
 * what the system actually does.
 */
object MiniCopy {
    // Brand
    const val tagline = "Menos tela. Mais presença."
    const val appName = "Mini Focus"

    // Navigation
    const val navToday = "Hoje"
    const val navModes = "Modos"
    const val navTag = "Mini Tag"

    // Home — focus off
    const val homeOffTitle = "Foco desligado"
    const val homeOffBody = "Aproxime seu celular do Mini Tag para começar."
    const val homeOffCTA = "Ler Mini Tag"

    // Home — focus on
    const val homeOnTitle = "Seu foco está ativo."
    const val homeOnBody = "Os aplicativos que você escolheu estão limitados."
    const val homeOnCTA = "Ler Mini Tag para encerrar"

    // Home — states
    const val homePrepareTitle = "Configure seu primeiro modo."
    const val homePrepareBody = "Escolha os aplicativos que o Mini Focus poderá limitar."
    const val homeStartWithoutTag = "Iniciar sem Mini Tag"
    fun homeActiveSince(time: String) = "Desde $time"

    // Permission (accessibility)
    const val permissionTitle = "Ative o serviço de acessibilidade."
    const val permissionBody =
        "Sem essa permissão, o Mini Focus não consegue limitar os aplicativos."
    const val permissionCTA = "Abrir configurações"

    // Alerts — no mode
    const val noModeTitle = "Nenhum modo selecionado"
    const val noModeBody = "Crie ou selecione um modo antes de iniciar o foco."

    // NFC errors
    const val nfcErrorTitle = "Erro de leitura"
    const val nfcUnavailable = "O NFC não está disponível neste aparelho."
    const val nfcNoTag = "Nenhum Mini Tag detectado."
    const val nfcReadFailedGeneric = "Não foi possível ler o Mini Tag."
    const val nfcWriteFailedGeneric = "Não foi possível gravar o Mini Tag."
    const val nfcReadOnly = "Este tag é somente leitura."
    const val nfcNotCompliant = "Este tag não é compatível com NDEF."
    const val nfcBuildPayload = "Não foi possível preparar os dados."
    fun nfcWriteFailed(message: String) = "Falha ao gravar: $message"
    const val tagUnknownTitle = "Mini Tag não conectado"

    // NFC prompt (in-app sheet)
    const val nfcScanPrompt = "Aproxime a parte de trás do celular do Mini Tag."
    const val nfcScanning = "Procurando Mini Tag…"

    // Modes
    const val modesTitle = "Modos"
    const val modesHint = "Toque para selecionar. Toque e segure para editar."
    const val modesNew = "Novo modo"
    const val modesEmptyTitle = "Nenhum modo ainda"
    const val modesEmptyBody = "Crie um modo para escolher quais aplicativos limitar."

    // Mode form
    const val modeAddTitle = "Novo modo"
    const val modeEditTitle = "Editar modo"
    const val modeDetailsSection = "Detalhes do modo"
    const val modeNameLabel = "Nome do modo"
    const val modeNamePlaceholder = "Digite o nome do modo"
    const val modeChooseIcon = "Escolher ícone"
    const val modeAppsSection = "Aplicativos"
    const val modeConfigureApps = "Escolher aplicativos"
    const val modeAppsBlocked = "Aplicativos limitados:"
    const val modePrivacyNote =
        "O Mini Focus só limita os aplicativos que você marcar. A lista fica apenas neste aparelho."
    const val modeDelete = "Excluir modo"
    const val modeDeleteTitle = "Excluir modo"
    const val modeDeleteBody =
        "Deseja excluir este modo? Os Mini Tags vinculados serão desvinculados."
    const val modeActiveDeleteTitle = "Modo em uso"
    const val modeActiveDeleteBody = "Encerre o foco ativo antes de excluir este modo."
    const val modeIconPickerTitle = "Escolha um ícone"
    const val modeSelectAppsTitle = "Selecionar aplicativos"
    const val modeAppsSearchPlaceholder = "Buscar aplicativo"
    fun modeAppsCount(count: Int) =
        if (count == 1) "1 aplicativo limitado" else "$count aplicativos limitados"

    // Mini Tag list
    const val tagsTitle = "Mini Tags"
    const val tagsEmptyTitle = "Nenhum Mini Tag conectado"
    const val tagsEmptyBody = "Conecte um Mini Tag para ativar o foco com um gesto."
    const val tagsAdd = "Conectar Mini Tag"
    const val tagNoMode = "Sem modo vinculado"
    fun tagLinkedMode(name: String) = "→ $name"

    // Mini Tag pairing
    const val pairingTitle = "Conectar Mini Tag"
    const val pairingTagSection = "Mini Tag"
    const val pairingScan = "Ler Mini Tag"
    const val pairingScanning = "Lendo…"
    fun pairingAlready(name: String) = "Já conectado como $name"
    const val pairingNameSection = "Nome"
    const val pairingNamePlaceholder = "ex.: Casa, Escritório, Chaveiro"
    const val pairingModeSection = "Modo (opcional)"
    fun pairingRegisterError(message: String) = "Não foi possível conectar o Mini Tag: $message"

    // Mini Tag detail
    const val tagNameSection = "Nome"
    const val tagNamePlaceholder = "Nome do Mini Tag"
    const val tagModeSection = "Modo"
    const val tagInfoSection = "Informações"
    const val tagIdentifier = "Identificador"
    const val tagIdentifierUnknown = "Desconhecido"
    const val tagRegistered = "Conectado em"
    const val tagWrite = "Gravar marcador no Mini Tag"
    const val tagWriteSuccess = "Marcador gravado."
    fun tagWriteError(message: String) = "Falha ao gravar: $message"
    const val tagDelete = "Remover Mini Tag"
    const val tagDeleteTitle = "Remover Mini Tag"
    const val tagDeleteBody =
        "Remover esta conexão? O Mini Tag físico pode ser conectado novamente depois."

    const val modePickerNone = "Sem modo vinculado"

    // Generic actions
    const val actionOK = "OK"
    const val actionCancel = "Cancelar"
    const val actionSave = "Salvar"
    const val actionDone = "Concluir"
    const val actionDelete = "Excluir"
    const val actionRemove = "Remover"

    // Default mode name
    const val defaultModeName = "Meu foco"

    // Block screen
    const val blockBody = "Toque para voltar à tela inicial e continuar focado."
    const val blockGoHome = "Voltar para a tela inicial"
}
