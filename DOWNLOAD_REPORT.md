# 100 PRA GLÓRIA — relatório de coleta de assets

Data da coleta: 2026-11-24
Branch: `assets/collection`
Projeto inspecionado: `100pra-gloria-godot` (o checkout original continha somente `README.md`; nenhum código foi alterado)

## Resultado

Foi adicionada uma biblioteca pública de 2.000+ arquivos, organizada em `asset_library/raw/`, com as licenças preservadas em `asset_library/licenses/` e o inventário completo em `asset_library/catalog.json`.

| Área | Conteúdo coletado | Cobertura para o jogo |
|---|---:|---|
| Gráficos | 223 arquivos Kenney Sports Pack | placeholders top-down, bolas, gols, peças de campo e objetos esportivos |
| UI | 1.193 arquivos Kenney | painéis, botões, ícones, controles touch e partículas |
| Áudio | 316 arquivos Kenney OGG | impactos, feedback de interface e jingles |
| Fontes | Rajdhani + Bebas Neue | duas famílias adequadas para HUD, placar e títulos |
| Identidade | 271 bandeiras SVG + `country.json` | nacionalidades e competições; não inclui escudos de clubes |
| Dados | 14 arquivos | Série A 2026, Libertadores 2025/2026, referências JSON e Mundial de Clubes 2025 |

Tamanho aproximado da coleção: **29 MB**.

## Escudos, fotos, clubes e jogadores

- Clubes da Série A 2026: a tabela de 20 equipes foi coletada em `asset_library/raw/data/openfootball_south_america/brazil/2026_br1.txt` e em `asset_library/raw/data/openfootball_json/2026/br.1.json`.
- Escudos dos 20 clubes e dos adversários: **não coletados**. Footylogos/Wikimedia/Wikidata exigem verificação individual de direitos e titularidade; nenhum logo de marca foi publicado sem essa checagem.
- Fotos individuais de jogadores e reservas vinculadas por ID: **não coletadas**. Não há roster 2026 completo licenciado no snapshot escolhido e fotos envolvem direitos de imagem.
- Silhuetas alternativas: podem ser derivadas depois pelo jogo a partir do placeholder top-down CC0; nenhuma imagem de pessoa real foi usada.

## Competições e dados

Disponível:

- Brasileirão Série A 2026, 20 equipes e 380 partidas no snapshot `openfootball/south-america`.
- Copa Libertadores 2025 e 2026 no mesmo repositório.
- Dados JSON da Série A 2026 em `openfootball/football.json`.
- Mundial de Clubes 2025 como referência histórica; não foi tratado como calendário de 2026.

Faltam, para uma temporada 2026 completa e verificada: Copa do Brasil, estaduais, Série B/C/D conforme os clubes envolvidos, Sul-Americana, Recopa, Supercopa e qualquer torneio FIFA aplicável. O projeto ainda não recebeu elencos, posições, idades, nacionalidades, atributos, estádios ou regulamentos completos.

## Bloqueios e decisões de licença

- O download direto do domínio Kenney retornou `403` neste ambiente. Os arquivos foram obtidos de um espelho público do conteúdo original, com os `License.txt` dos próprios pacotes preservados e os links das páginas oficiais registrados no catálogo.
- Kenney foi incluído somente para pacotes cuja página oficial informa CC0.
- `flag-icons` foi incluído sob MIT, com a licença preservada.
- Rajdhani e Bebas Neue foram incluídas sob SIL OFL 1.1, com as respectivas licenças preservadas.
- Não foram incluídos downloads de Freesound, Pixabay, Mixkit, footylogos, Wikimedia/Wikidata ou Kaggle sem concluir a verificação individual da licença/redistribuição do arquivo original.
- Não foram baixados packs enormes, duplicatas, conteúdo restrito, arquivos com login obrigatório ou ativos de licença incerta.

## Commits e envio

- Preparação local — lote gráfico/UI: `b610c3c` — `assets: add graphics and mobile UI collection`.
- Preparação local — lote áudio/identidade/fontes/dados: `833490a` — `assets: add audio identity fonts and football data`.
- Publicação remota: **não concluída**. `git push` falhou por falta de credencial HTTPS; a rota do conector GitHub foi tentada, mas uploads de blobs grandes falharam intermitentemente antes da criação do commit.
- Branch remota: `https://github.com/jorgeramossilva15p-ctrl/100pra-gloria-godot/tree/assets/collection`

O clone local contém a branch completa e três commits prontos. O remoto ainda aponta para o commit inicial; é necessário autenticar o GitHub e executar `git push -u origin assets/collection` a partir deste checkout para concluir o envio.
