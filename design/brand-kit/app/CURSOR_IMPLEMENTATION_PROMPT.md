# Prompt para Cursor — adaptação do Broke para Mini Focus

Objetivo: criar identidade e UX próprias no aplicativo iOS existente, preservando funcionalidades já existentes, e preparar o projeto para distribuição comercial.

Referências neste pacote:
- `brand/BRAND_GUIDELINES.md`
- `brand/design-tokens.json`
- `brand/MiniTokens.swift`
- `app/UX_SPEC.md`
- `app/strings.pt-BR.json`
- `app/IOS_TECH_NOTES.md`
- `assets/` (símbolo, logotipo e ícones)

Tarefas:
1. Inspecione a arquitetura Swift/SwiftUI atual e produza um inventário dos componentes, fluxos de NFC, permissões de Screen Time e perfis, com evidências por arquivo.
2. Proponha alterações incrementais; não reescreva o motor de bloqueio ou o fluxo NFC sem testes de regressão.
3. Substitua strings e assets visuais Broke por Mini Focus, com os tokens e cópias fornecidos. Não remova avisos e licenças open source.
4. Refaça onboarding, Hoje, Modos, Mini Tag e Ajustes, com suporte a estados vazios, erros e perda de permissão.
5. Faça a tipografia seguir Dynamic Type e os controles respeitarem acessibilidade nativa.
6. Use os recursos oficiais do iOS. Não prometa desbloqueio automático por NFC de background sem avaliar o comportamento real do sistema.
7. Adicione testes e um checklist manual para iPhone real, especialmente ativação/desativação com tag e permissão revogada.
8. Gere screenshots reais de teste e prepare assets/App Store sem usar nome, UI ou trade dress do Brick.
9. Liste explicitamente o que exige aprovação de entitlement Family Controls para distribuição.

Entregue primeiro um plano de mudanças por arquivo com riscos técnicos, depois implemente em pequenos commits.
