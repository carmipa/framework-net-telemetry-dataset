# Dataset de telemetria — Framework de Redes

Gerado em 2026-08-04 00:59:44 UTC a partir da telemetria de produção de
[frameworknet.carminati.dev.br](https://frameworknet.carminati.dev.br).

`173` registros publicados.
Formato: **NDJSON**, um OpenTelemetry `LogRecord` por linha (`eventos.jsonl`).
Esquema completo em `schema.json`; contagens em `estatisticas.json`.

## O que foi removido antes de publicar

| Dado original | Tratamento | Motivo |
|---|---|---|
| IP do visitante | SHA-256 com sal secreto, truncado em 12 hex (`framework.field.ip_hash`) | Identifica pessoa. O sal fica na VPS e nunca entra neste repositório, então o hash não é reversível. Como é estável, ainda dá para contar visitantes únicos. |
| Coordenadas de GPS (`lat`/`lon`) | **Removidas** | 6 casas decimais são ~10 cm de precisão. Nem hash nem arredondamento tornam isso publicável. |
| Hostname/domínio quando era um IP | Pseudonimizado como acima | Mesmo risco do IP. |
| Estáticos, `/q/*`, `/web/*`, `/telemetria/api*` | Descartados (21 registros) | Ruído de infraestrutura, não descreve uso do sistema. |

O campo `body` é **reconstruído** a partir dos atributos já sanitizados. Ele
repetia os valores em texto livre (`evento=geo_lookup status=ok ip=...`), então
limpar apenas os atributos deixaria o dado sensível no texto.

Um passo de auditoria varre o arquivo final atrás de IPv4 público e coordenadas
residuais; a geração falha se encontrar qualquer um. IPs de faixa privada,
loopback e documentação permanecem — são os valores de laboratório do próprio
material didático.

## Limitações conhecidas

- **37 registro(s) sem `traceId`.** Eventos nascidos
  fora de uma requisição (inicialização da aplicação, tarefas de fundo) não têm
  correlação, e isso é correto. Registros de requisição sem `traceId` são de
  coletas anteriores a 2026-08-03, quando os eventos de negócio passaram a herdar
  a correlação do request.
- **`GET /` inclui o healthcheck do container.** O Docker consulta a raiz a cada
  30 s e a telemetria não distingue isso de uma visita real. Trate a contagem de
  `GET /` como limite superior, não como visitas.
- Um incidente rende mais de um evento (operação, exceção mapeada, acesso HTTP).
  **Agrupe por `traceId`** para contar incidentes em vez de linhas.

## Como usar

```bash
# eventos de erro, agrupados por incidente
jq -r 'select(.severityText=="ERROR") | .traceId' eventos.jsonl | sort -u | wc -l

# uso por módulo
jq -r '.attributes[] | select(.key=="framework.module") | .value.stringValue' \
  eventos.jsonl | sort | uniq -c | sort -rn
```
