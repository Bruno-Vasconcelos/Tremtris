# Campanha: cozinheiro vs 3 chefões — GDD mínimo

## Premissa

Um cozinheiro desafia três chefões em uma linha de produção estilo quebra-cabeça: cada ato introduz uma regra nova no tabuleiro; o 5º confronto de cada ato é um **boss com vitória por regra especial** (não só meta de pontos).

## Ato 1 — “Bistrô da esquina” (fases 1–4 + boss)

**Mecânica:** obstáculos com durabilidade (restos endurecidos na grelha). O chefão fica com **escudo** enquanto existir obstáculo: a pontuação só “conta” depois de limpar os blocos fixos.

**Boss 1 — Bruto da Grelha:** vitória ao **limpar N linhas** nesta fase (modo `lines`). Derrota: peça trava no topo (mesmo game over). UI: barra de progresso por linhas, não por pontos.

## Ato 2 — “Salão gourmet” (fases 6–9 + boss)

**Mecânica:** **pedidos** — uma fileira do tabuleiro fica destacada como “pedido do salão”. Ao completar uma linha que inclua essa fileira, o pedido avança e a marca muda de lugar. Nas fases normais isso dá **bônus de pontuação**; no boss é obrigatório.

**Boss 2 — Crítico de Salão:** vitória ao **servir N pedidos** (completar a fileira destacada N vezes, modo `orders`). Derrota: game over por topo.

## Ato 3 — “Banquete final” (fases 11–14 + boss)

**Mecânica:** **pressão** — gravidade mais agressiva (`gravity_mult` menor que 1) + obstáculos retornam em padrões maiores. Combina decisão rápida com limpeza de escudo.

**Boss 3 — Estrela Michelin:** vitória ao **limpar M linhas** com gravidade máxima do jogo (modo `lines` com alvo alto). Derrota: game over.

## Progressão e save

- 15 fases indexadas 0–14; vitória na última encerra a campanha.
- **Menu principal** ao iniciar o jogo (`main_menu.tscn`):
  - **Novo jogo** — começa na fase 1 com save zerado.
  - **Carregar última fase** — retoma na fase salva (desabilitado se nunca jogou).
  - **Seleção de fases** — grid com desbloqueio progressivo (só fases já alcançadas).
- Progresso salvo em `user://` após cada fase concluída (`stage_index`, `highest_unlocked_stage`, `has_progress`).
- **R:** reinicia a campanha do zero durante o jogo.
- **T** (com game over): tenta de novo **a mesma fase** sem apagar o save.
- **M** (pause, game over ou vitória): volta ao menu principal.

## Produto de limpeza

- Desbloqueado após vencer o **Boss 1** (fase 5 — Bruto da Grelha).
- Tecla **L**: remove 1 ponto de durabilidade do obstáculo **mais resistente** (empate: mais baixo, depois mais à esquerda).
- Cooldown base de **60 s**; cada linha limpa reduz **5 s** do tempo restante.
- Cooldown zera ao iniciar cada fase; desbloqueio persiste no save.
- Flag de teste `TEST_UNLOCK_ALL_STAGES` em `campaign_save.gd`: desbloqueia todas as fases no seletor e o item de limpeza.

## Identidade comercial (venda única PC)

Ver [steam_store_copy.md](steam_store_copy.md) para texto de loja, bullets e sugestão de demo.
