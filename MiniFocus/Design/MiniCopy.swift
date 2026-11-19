//
//  MiniCopy.swift
//  MiniFocus
//
//  Centralized user-facing copy for Mini Focus, in Brazilian Portuguese.
//
//  Every visible string lives here as `String(localized:)` so the app is ready
//  for future localization. Voice: calm, direct, trustworthy. Short sentences,
//  active voice, no punitive or infantilizing language.
//

import Foundation

enum MiniCopy {
    // MARK: Brand
    static let tagline = String(localized: "brand.tagline", defaultValue: "Menos tela. Mais presença.")
    static let appName = String(localized: "brand.appName", defaultValue: "Mini Focus")

    // MARK: Navigation
    static let navToday = String(localized: "nav.today", defaultValue: "Hoje")
    static let navModes = String(localized: "nav.modes", defaultValue: "Modos")
    static let navTag = String(localized: "nav.tag", defaultValue: "Mini Tag")

    // MARK: Home — focus off
    static let homeOffTitle = String(localized: "home.off.title", defaultValue: "Foco desligado")
    static let homeOffBody = String(localized: "home.off.body", defaultValue: "Aproxime seu iPhone do Mini Tag para começar.")
    static let homeOffCTA = String(localized: "home.off.cta", defaultValue: "Ler Mini Tag")

    // MARK: Home — focus on
    static let homeOnTitle = String(localized: "home.on.title", defaultValue: "Seu foco está ativo.")
    static let homeOnBody = String(localized: "home.on.body", defaultValue: "Os aplicativos que você escolheu estão limitados.")
    static let homeOnCTA = String(localized: "home.on.cta", defaultValue: "Ler Mini Tag para encerrar")

    // MARK: Home — states
    static let homePrepareTitle = String(localized: "home.prepare.title", defaultValue: "Configure seu primeiro modo.")
    static let homePrepareBody = String(localized: "home.prepare.body", defaultValue: "Escolha os aplicativos que o Mini Focus poderá limitar.")
    static let homeStartWithoutTag = String(localized: "home.startWithoutTag", defaultValue: "Iniciar sem Mini Tag")
    static func homeActiveSince(_ time: String) -> String {
        String(localized: "home.active.since", defaultValue: "Desde \(time)")
    }

    // MARK: Permission
    static let permissionTitle = String(localized: "permissions.title", defaultValue: "Autorize o Tempo de Uso.")
    static let permissionBody = String(localized: "permissions.body", defaultValue: "Sem essa permissão, o Mini Focus não consegue limitar os aplicativos.")
    static let permissionCTA = String(localized: "permissions.cta", defaultValue: "Autorizar")

    // MARK: Alerts — no mode
    static let noModeTitle = String(localized: "alert.noMode.title", defaultValue: "Nenhum modo selecionado")
    static let noModeBody = String(localized: "alert.noMode.body", defaultValue: "Crie ou selecione um modo antes de iniciar o foco.")

    // MARK: NFC errors
    static let nfcErrorTitle = String(localized: "alert.nfc.title", defaultValue: "Erro de leitura")
    static let nfcUnavailable = String(localized: "nfc.unavailable", defaultValue: "O NFC não está disponível neste aparelho.")
    static let nfcNoTag = String(localized: "nfc.noTag", defaultValue: "Nenhum Mini Tag detectado.")
    static let tagUnknownTitle = String(localized: "tag.unknown.title", defaultValue: "Mini Tag não conectado")

    // MARK: Modes
    static let modesTitle = String(localized: "modes.title", defaultValue: "Modos")
    static let modesHint = String(localized: "modes.hint", defaultValue: "Toque para selecionar. Toque e segure para editar.")
    static let modesNew = String(localized: "modes.new", defaultValue: "Novo modo")
    static let modesEmptyTitle = String(localized: "modes.empty.title", defaultValue: "Nenhum modo ainda")
    static let modesEmptyBody = String(localized: "modes.empty.body", defaultValue: "Crie um modo para escolher quais aplicativos limitar.")

    // MARK: Mode form
    static let modeAddTitle = String(localized: "mode.add.title", defaultValue: "Novo modo")
    static let modeEditTitle = String(localized: "mode.edit.title", defaultValue: "Editar modo")
    static let modeDetailsSection = String(localized: "mode.details.section", defaultValue: "Detalhes do modo")
    static let modeNameLabel = String(localized: "mode.name.label", defaultValue: "Nome do modo")
    static let modeNamePlaceholder = String(localized: "mode.name.placeholder", defaultValue: "Digite o nome do modo")
    static let modeChooseIcon = String(localized: "mode.chooseIcon", defaultValue: "Escolher ícone")
    static let modeAppsSection = String(localized: "mode.apps.section", defaultValue: "Aplicativos")
    static let modeConfigureApps = String(localized: "mode.configureApps", defaultValue: "Escolher aplicativos")
    static let modeAppsBlocked = String(localized: "mode.apps.blocked", defaultValue: "Aplicativos limitados:")
    static let modeCategoriesBlocked = String(localized: "mode.categories.blocked", defaultValue: "Categorias limitadas:")
    static let modeWebsitesBlocked = String(localized: "mode.websites.blocked", defaultValue: "Sites limitados:")
    static let modePrivacyNote = String(localized: "mode.privacy.note", defaultValue: "Por privacidade, o Mini Focus não vê os nomes dos aplicativos — apenas a quantidade selecionada.")
    static let modeDelete = String(localized: "mode.delete", defaultValue: "Excluir modo")
    static let modeDeleteTitle = String(localized: "mode.delete.title", defaultValue: "Excluir modo")
    static let modeDeleteBody = String(localized: "mode.delete.body", defaultValue: "Deseja excluir este modo? Os Mini Tags vinculados serão desvinculados.")
    static let modeActiveDeleteTitle = String(localized: "mode.activeDelete.title", defaultValue: "Modo em uso")
    static let modeActiveDeleteBody = String(localized: "mode.activeDelete.body", defaultValue: "Encerre o foco ativo antes de excluir este modo.")
    static let modeIconPickerTitle = String(localized: "mode.iconPicker.title", defaultValue: "Escolha um ícone")
    static let modeSelectAppsTitle = String(localized: "mode.selectApps.title", defaultValue: "Selecionar aplicativos")

    // MARK: Mode form — Strict Mode / Modo Segurança
    static let modeProtectionSection = String(localized: "mode.protection.section", defaultValue: "Proteção")
    static let modeStrictToggle = String(localized: "mode.strict.toggle", defaultValue: "Strict Mode")
    static let modeStrictFooter = String(localized: "mode.strict.footer", defaultValue: "Quando ativado, este modo não poderá ser encerrado manualmente pelo Mini. Para sair, será necessário aproximar uma tag NFC autorizada.")
    static let modeSecurityToggle = String(localized: "mode.security.toggle", defaultValue: "Modo Segurança")
    static let modeSecurityFooter = String(localized: "mode.security.footer", defaultValue: "Oculta completamente os aplicativos selecionados enquanto este modo estiver ativo. Ideal para bancos, e-mail e outros aplicativos sensíveis.")
    static let modeSecurityAppsOnly = String(localized: "mode.security.appsOnly", defaultValue: "O Modo Segurança protege apenas aplicativos. Categorias e sites selecionados serão ignorados.")
    static let modeSecurityNeedsApps = String(localized: "mode.security.needsApps", defaultValue: "Selecione ao menos um aplicativo para usar o Modo Segurança.")
    static let modeLockedEditNotice = String(localized: "mode.locked.editNotice", defaultValue: "Este modo está ativo e bloqueado. Aproxime sua Mini Tag para encerrar a sessão antes de editar.")

    // MARK: Home — active session (Strict / Security)
    static let homeStrictBadge = String(localized: "home.strict.badge", defaultValue: "🔒 Strict Mode")
    static let homeStrictInstruction = String(localized: "home.strict.instruction", defaultValue: "Para encerrar esta sessão, aproxime sua Mini Tag.")
    static let homeEndFocus = String(localized: "home.endFocus", defaultValue: "End Focus")
    static let homeStrictAlertTitle = String(localized: "home.strict.alert.title", defaultValue: "Strict Mode ativo")
    static let homeStrictAlertBody = String(localized: "home.strict.alert.body", defaultValue: "Esta sessão só pode ser encerrada usando uma Mini Tag autorizada.")
    static let homeSecurityBanner = String(localized: "home.security.banner", defaultValue: "🛡 Modo Segurança ativo — Os aplicativos protegidos estão ocultos. Aproxime sua Mini Tag para desativar o Modo Segurança.")

    // MARK: Home — denials / guards
    static let homeLockedUnknownTag = String(localized: "home.locked.unknownTag", defaultValue: "Mini Tag não reconhecido. Aproxime a Mini Tag autorizada para encerrar.")
    static let homeLockedOtherModeTag = String(localized: "home.locked.otherModeTag", defaultValue: "Esta Mini Tag está vinculada a outro modo e não encerra esta sessão.")
    static let homeLockedNoTagTitle = String(localized: "home.locked.noTag.title", defaultValue: "Mini Tag necessária")
    static let homeLockedNoTagBody = String(localized: "home.locked.noTag.body", defaultValue: "Este modo é bloqueado. Conecte ao menos uma Mini Tag a ele antes de ativá-lo, para que você sempre consiga encerrar a sessão.")
    static let homeSecurityNoAppsTitle = String(localized: "home.security.noApps.title", defaultValue: "Nenhum aplicativo protegido")
    static let homeSecurityNoAppsBody = String(localized: "home.security.noApps.body", defaultValue: "Escolha ao menos um aplicativo neste modo antes de ativar o Modo Segurança.")
    static let homeNotAuthorizedTitle = String(localized: "home.notAuthorized.title", defaultValue: "Autorização necessária")
    static let homeNotAuthorizedBody = String(localized: "home.notAuthorized.body", defaultValue: "Autorize o Tempo de Uso para que o Mini Focus possa limitar os aplicativos.")
    static let homeActivationFailedTitle = String(localized: "home.activationFailed.title", defaultValue: "Não foi possível ativar")
    static let homeActivationFailedBody = String(localized: "home.activationFailed.body", defaultValue: "O sistema não aplicou as restrições. Tente novamente.")

    // MARK: Tags — locked session freeze
    static let tagLockedNotice = String(localized: "tag.locked.notice", defaultValue: "Há uma sessão bloqueada ativa. Encerre-a com sua Mini Tag para gerenciar os Mini Tags.")

    // MARK: Mini Tag list
    static let tagsTitle = String(localized: "tags.title", defaultValue: "Mini Tags")
    static let tagsEmptyTitle = String(localized: "tags.empty.title", defaultValue: "Nenhum Mini Tag conectado")
    static let tagsEmptyBody = String(localized: "tags.empty.body", defaultValue: "Conecte um Mini Tag para ativar o foco com um gesto.")
    static let tagsAdd = String(localized: "tags.add", defaultValue: "Conectar Mini Tag")
    static let tagNoMode = String(localized: "tags.noMode", defaultValue: "Sem modo vinculado")
    static func tagLinkedMode(_ name: String) -> String {
        String(localized: "tags.linkedMode", defaultValue: "→ \(name)")
    }

    // MARK: Mini Tag pairing
    static let pairingTitle = String(localized: "pairing.title", defaultValue: "Conectar Mini Tag")
    static let pairingTagSection = String(localized: "pairing.tag.section", defaultValue: "Mini Tag")
    static let pairingScan = String(localized: "pairing.scan", defaultValue: "Ler Mini Tag")
    static let pairingScanning = String(localized: "pairing.scanning", defaultValue: "Lendo…")
    static func pairingAlready(_ name: String) -> String {
        String(localized: "pairing.already", defaultValue: "Já conectado como \(name)")
    }
    static let pairingNameSection = String(localized: "pairing.name.section", defaultValue: "Nome")
    static let pairingNamePlaceholder = String(localized: "pairing.name.placeholder", defaultValue: "ex.: Casa, Escritório, Chaveiro")
    static let pairingModeSection = String(localized: "pairing.mode.section", defaultValue: "Modo (opcional)")
    static func pairingRegisterError(_ message: String) -> String {
        String(localized: "pairing.register.error", defaultValue: "Não foi possível conectar o Mini Tag: \(message)")
    }

    // MARK: Mini Tag detail
    static let tagNameSection = String(localized: "tag.name.section", defaultValue: "Nome")
    static let tagNamePlaceholder = String(localized: "tag.name.placeholder", defaultValue: "Nome do Mini Tag")
    static let tagModeSection = String(localized: "tag.mode.section", defaultValue: "Modo")
    static let tagInfoSection = String(localized: "tag.info.section", defaultValue: "Informações")
    static let tagIdentifier = String(localized: "tag.identifier", defaultValue: "Identificador")
    static let tagIdentifierUnknown = String(localized: "tag.identifier.unknown", defaultValue: "Desconhecido")
    static let tagRegistered = String(localized: "tag.registered", defaultValue: "Conectado em")
    static let tagWrite = String(localized: "tag.write", defaultValue: "Gravar marcador no Mini Tag")
    static let tagWriteSuccess = String(localized: "tag.write.success", defaultValue: "Marcador gravado.")
    static func tagWriteError(_ message: String) -> String {
        String(localized: "tag.write.error", defaultValue: "Falha ao gravar: \(message)")
    }
    static let tagDelete = String(localized: "tag.delete", defaultValue: "Remover Mini Tag")
    static let tagDeleteTitle = String(localized: "tag.delete.title", defaultValue: "Remover Mini Tag")
    static let tagDeleteBody = String(localized: "tag.delete.body", defaultValue: "Remover esta conexão? O Mini Tag físico pode ser conectado novamente depois.")

    static let modePickerNone = String(localized: "modePicker.none", defaultValue: "Sem modo vinculado")

    // MARK: Generic actions
    static let actionOK = String(localized: "action.ok", defaultValue: "OK")
    static let actionCancel = String(localized: "action.cancel", defaultValue: "Cancelar")
    static let actionSave = String(localized: "action.save", defaultValue: "Salvar")
    static let actionDone = String(localized: "action.done", defaultValue: "Concluir")
    static let actionDelete = String(localized: "action.delete", defaultValue: "Excluir")
    static let actionRemove = String(localized: "action.remove", defaultValue: "Remover")

    // MARK: Default mode name
    static let defaultModeName = String(localized: "mode.default.name", defaultValue: "Meu foco")

    // MARK: NFC session prompts (system sheet)
    static let nfcScanPrompt = String(localized: "nfc.prompt.scan", defaultValue: "Aproxime a parte superior do iPhone do Mini Tag.")
    static let nfcWritePrompt = String(localized: "nfc.prompt.write", defaultValue: "Aproxime a parte superior do iPhone do Mini Tag para gravar.")
    static let nfcMultipleTags = String(localized: "nfc.session.multiple", defaultValue: "Mais de um tag detectado. Apresente apenas um.")
    static let nfcNoTagDetected = String(localized: "nfc.session.noTag", defaultValue: "Nenhum Mini Tag detectado.")
    static let nfcTagRead = String(localized: "nfc.session.read", defaultValue: "Mini Tag lido.")
    static let nfcTagWritten = String(localized: "nfc.session.written", defaultValue: "Mini Tag gravado.")
    static let nfcNotCompliant = String(localized: "nfc.session.notCompliant", defaultValue: "Este tag não é compatível com NDEF.")
    static let nfcReadOnly = String(localized: "nfc.session.readOnly", defaultValue: "Este tag é somente leitura.")
    static let nfcBuildPayload = String(localized: "nfc.session.payload", defaultValue: "Não foi possível preparar os dados.")
    static let nfcUnknownStatus = String(localized: "nfc.session.unknown", defaultValue: "Estado do tag desconhecido.")
    static func nfcConnectionError(_ message: String) -> String {
        String(localized: "nfc.session.connection", defaultValue: "Erro de conexão: \(message)")
    }
    static func nfcQueryFailed(_ message: String) -> String {
        String(localized: "nfc.session.query", defaultValue: "Falha ao consultar o tag: \(message)")
    }
    static func nfcWriteFailed(_ message: String) -> String {
        String(localized: "nfc.session.writeFailed", defaultValue: "Falha ao gravar: \(message)")
    }
}
