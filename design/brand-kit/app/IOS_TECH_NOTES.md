# Mini Focus — Notas técnicas de iOS e portabilidade do Broke

## Base técnica
- O Broke é um projeto iOS open-source Apache-2.0 com múltiplos perfis, NFC e gravação de tag (README do repositório).
- Preservar a licença Apache-2.0, avisos de copyright e atribuições do código reutilizado; verificar dependências e assets de terceiros.
- Refazer logotipo, ícones, nomes internos de UI, strings, documentação e screenshots, não somente o nome visível.

## Restrições e integração Apple
1. Screen Time: `FamilyControls`, `ManagedSettings` e, se necessário, `DeviceActivity`.
2. Para distribuir, obter a autorização do entitlement **Family Controls** para app e extensões aplicáveis.
3. NFC: `CoreNFC` suporta leitura e gravação de tags NDEF via sessão ativa.
4. NFC em segundo plano (iPhone XS+): tags com **universal link HTTPS** disparam notificação do sistema; o usuário toca na notificação e pode precisar desbloquear o aparelho. **Não pressupor alternância automática invisível**.
5. Para permitir links universais: Associated Domains + apple-app-site-association; domínio precisa ser escolhido e configurado.
6. Não prometer bloqueio absoluto ou senha de sistema personalizada; checar e lidar com permissões revogadas.
7. Nome/pacote a definir após validação comercial e domínio. Evitar reusar identificadores 'Broke' ou 'Brick'.

## Modelo de dados sugerido
- Mode: uuid, displayName, familyActivitySelection (tokens locais), enabled.
- MiniTag: uuid, humanLabel, ndefVersion, createdAt, active.
- FocusSession: id, modeId, startedAt, endedAt, activationSource, endReason.
- Preferir armazenamento local; não armazenar listas identificáveis de uso sem motivo e consentimento claros.

## Payload de tag (exemplo, não padrão publicado)
- Link universal: `https://<dominio-validado>/t/<token-opaco>` em NDEF URI.
- Token opaco randômico, não incluir nome, telefone ou email.
- NTAG213 serve para protótipos; testar inlay, alcance e comportamento em aparelhos reais.
- Atenção: tags NFC básicas são clonáveis; não vender a identificação por NFC simples como prova criptográfica.

## Referências
- https://github.com/OzTamir/broke
- https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
- https://developer.apple.com/documentation/corenfc/adding-support-for-background-tag-reading
- https://developer.apple.com/documentation/corenfc/building-an-nfc-tag-reader-app
- https://developer.apple.com/design/human-interface-guidelines/app-icons
