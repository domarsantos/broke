# Mini Focus — Kit de marca v1.0

Este kit reúne uma **proposta de identidade e especificações para implementação**, não uma identidade já registrada nem um hardware pronto para produção.

## Entregas
1. Nome/arquitetura: `brand/BRAND_GUIDELINES.md`
2. Logo: `assets/mini-focus-logo-*.svg` e `assets/mini-mark-*.svg`
3. Design system: `brand/design-tokens.json`, `.css`, `MiniTokens.swift`
4. UX: `app/UX_SPEC.md`
5. Textos: `app/strings.pt-BR.json`
6. Ícones: `app/UX_SPEC.md` (SF Symbols) e `assets/app-icon-*.png/.svg`
7. Linguagem visual: `brand/BRAND_GUIDELINES.md`, `assets/concept-board.png`
8. Tag e embalagem: `product/MINI_TAG_SPEC.md` e artes conceituais em `product/`

## Como usar
- Abra `assets/concept-board.png` para entender a direção estética.
- Incorpore `brand/MiniTokens.swift` no projeto Xcode.
- Configure o asset de ícone 1024 x 1024 em Xcode com `assets/app-icon-default.png`; variantes opcionais incluídas.
- Use `app/CURSOR_IMPLEMENTATION_PROMPT.md` para iniciar o trabalho no projeto Broke.
- Valide as versões físicas com fornecedor e as restrições de iOS com testes em aparelho real.

## Atenção antes de comercializar
- Já existe na App Store o aplicativo "Mini Focus Timer"; existem também registros de marca "MF MINI FOCUS" em algumas jurisdições. Não significa impedimento automático no Brasil, mas exige consulta ao INPI e análise de colisão para softwares/eletrônicos.
- A distribuição de apps com FamilyControls exige aprovação da Apple para o entitlement correspondente, inclusive em extensões.
- Leitura NFC em segundo plano não é garantidamente automática ou invisível: em muitos casos requer interação com notificação do sistema.
- Dimensões de Mini Tag, packaging, custo industrial e textos legais são **propostas**. Não levar a produção sem validar NFC, materiais, fornecedores e faca de impressão.
- Fonte Sora não está incluída; obter fonte sob seus termos de licença para uso na produção.

## Referências verificadas
- https://github.com/OzTamir/broke
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading
- https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
- https://apps.apple.com/us/app/mini-focus-timer/id6766460553
