# Mini Focus — UX/Produto v1.0

## Princípio do MVP
Numa sessão normal, o usuário não deve precisar olhar para o app: a relação física com a Mini Tag cria intenção.

## Sitemap
- **Hoje**: status atual (ligado/desligado), modo escolhido, último evento, CTA de leitura NFC, ajuda.
- **Modos**: criar/editar modo, lista de aplicativos a limitar, nome e ícone do modo.
- **Mini Tag**: vincular, renomear, testar leitura, recuperar conexão.
- **Ajustes**: permissão Tempo de Uso, privacidade, suporte, informações legais e licença OSS.

## Fluxo 1 — primeira utilização
1. Boas-vindas (benefício em 2 frases; sem criação obrigatória de conta).
2. Solicitar FamilyControls/Screen Time e tratar 'não permitir' sem erro fatal.
3. Selecionar apps/categorias pelo picker nativo e criar modo 'Meu foco'.
4. Vincular Mini Tag com sessão de leitura NFC ativa (ou gravação quando apropriado).
5. Testar **ativar** e **encerrar** foco em condições reais e confirmar estado.

## Fluxo 2 — uso recorrente
- Com a função permitida, usuário aproxima iPhone da Mini Tag; o app valida a tag cadastrada e alterna o modo conforme desenho técnico aprovado.
- Ao ativar: aplicar ManagedSettings; estado visível 'Seu foco está ativo'; feedback discreto/háptico quando disponível.
- Para encerrar: aproximar novamente da Mini Tag. Oferecer ação de recuperação/emergência clara, deliberada e compatível com as políticas do iOS.
- O app deve tratar erros de leitura, permissões revogadas e tags desconhecidas.

## Fluxo 3 — recuperação / emergências
- Usuário perdeu tag: 'Preciso de acesso emergencial' -> explicação -> confirmação -> fluxo de recuperação definido pela equipe.
- Nunca prometer inviolabilidade: no uso individual, o usuário tem controle de certas permissões do iOS.
- Sem permissão: orientar ao ajuste permitido pelo sistema, sem fingir que houve bloqueio.

## Estados fundamentais da Home
1. **Preparação**: 'Configure seu primeiro modo.'
2. **Pronto**: 'Foco desligado' / 'Aproxime seu iPhone do Mini Tag para começar.'
3. **Ativo**: 'Seu foco está ativo.' / modo atual / horário de início / apps limitados.
4. **Permissão perdida**: 'Para limitar apps, autorize o Tempo de Uso.'
5. **Tag desconhecida**: 'Este Mini Tag ainda não está conectado.'
6. **Erro**: 'Não foi possível concluir. Tente novamente.'

## Ícones — SF Symbols (a validar no deployment target)
- Hoje: `house`
- Modos: `square.stack.3d.up`
- Mini Tag: `wave.3.right`
- Ajustes: `gearshape`
- Iniciar foco: `circle.dotted.circle`
- Permissão: `lock.shield`
- Ajuda: `questionmark.circle`

## Fora de escopo da primeira versão
- Rede social, pontos e ranking, notificações persistentes, métricas de desempenho sofisticadas.
- Login/cloud obrigatório, painel administrativo e sincronização entre múltiplos usuários.

## Critérios de aceite
- Fluxo inicial concluído em poucos passos sem ambiguidade.
- Estado visual sempre corresponde ao estado real de bloqueio.
- Leitura in-app disponível mesmo sem background NFC.
- Dynamic Type, VoiceOver, contraste, estados sem cor exclusiva.
- Eventos de erro, perda de permissão, tag fora de alcance e app reinstalado tratados.
