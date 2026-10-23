# Snapshot 2026-10-23

Gerado a partir da telemetria de produção de
[frameworknet.carminati.dev.br](https://frameworknet.carminati.dev.br).

- Registros publicados: **498**
- Identificadores consultados distintos (IP, host ou endereço digitado nas ferramentas,
  pseudonimizado): **2** — não é contagem de visitantes do site

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `eventos.jsonl` | **fonte canonica** — NDJSON, um OpenTelemetry `LogRecord` por linha, com os atributos aninhados |
| `eventos.csv` | mesma informacao achatada, para abrir em planilha, pandas ou R |
| `schema.json` | formato e atributos |
| `estatisticas.json` | contagens, descartes e qualidade |

O CSV e **derivado** do JSONL, gerado a partir dos mesmos registros ja
sanitizados — nao e uma segunda extracao. Havendo divergencia entre os
dois, o JSONL manda: ele preserva a estrutura aninhada que o achatamento
do CSV precisa simplificar.

## Sanitização

| Dado original | Tratamento |
|---|---|
| IP, host ou endereço consultado | `id-NNN`, sequencial **dentro deste pacote** |
| Demais campos de evento | só os do esquema fechado (`schema.json`); texto livre, mensagem de erro, hostname, domínio, regra e rede ficam de fora |
| Rota | segmento que não é palavra fixa vira `{param}` |
| Coordenadas GPS | removidas |
| Campo `body` | reconstruído a partir dos atributos já sanitizados |
| Estáticos, `/q/*`, `/web/*`, `/telemetria/api*`, health | descartados |

**Não existe sal nem segredo por trás do pseudônimo.** O mapa de
identidades vive só durante a geração e é descartado. A consequência
aceita conscientemente: não dá para correlacionar o mesmo visitante
entre dois snapshots — em troca, não há segredo algum a guardar, e
nenhum vazamento futuro torna estes dados reversíveis.

Endereços IPv4 privados, de loopback e de documentação permanecem: são
valores de laboratório digitados pelos usuários para estudar, não
identificadores de pessoas.

A geração falha e nada é produzido se a auditoria final encontrar IP
público, coordenada ou e-mail residual no arquivo pronto.
