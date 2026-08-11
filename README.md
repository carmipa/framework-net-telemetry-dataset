# Framework Net — dataset público de telemetria

Telemetria real de produção do
**[Framework de Redes — Análise Didática Avançada](https://frameworknet.carminati.dev.br)**,
sanitizada e publicada em formato aberto.

Cada arquivo aqui é um **retrato datado** do que o sistema registrou em um momento.
Serve para estudar uso real de uma aplicação didática de redes: quais módulos são
procurados, quanto demoram, onde falham.

| | |
|---|---|
| Formato | NDJSON — um [OpenTelemetry `LogRecord`](https://opentelemetry.io/docs/specs/otel/logs/data-model/) por linha |
| Snapshots | 1 |
| Registros publicados | 173 |
| Licença dos dados | MIT (ver [LICENSE](LICENSE)) |
| Origem | `frameworknet.carminati.dev.br` · Java 25 + Quarkus |

---

## A regra que governa este repositório

> **Snapshot publicado nunca é sobrescrito. Só se acrescenta.**

Cada geração cria uma pasta nova em `dataset/<AAAA-MM-DD>/`. Uma pasta que já foi
publicada é **imutável**: não se edita, não se regenera por cima, não se apaga.

Não é preciosismo. Um dataset público serve para alguém citar, comparar e
reproduzir um resultado. Se o conteúdo de `2026-08-04` mudar depois que alguém o
citou, a citação passa a apontar para outra coisa — e ninguém é avisado. Correção
de um snapshot antigo se faz publicando um snapshot novo e explicando a diferença,
nunca reescrevendo o passado.

A regra é **verificada por script**, não só combinada:

```bash
bash scripts/verificar-append-only.sh
```

Ele reprova se algum arquivo dentro de um snapshot já commitado tiver sido
modificado ou removido. Rode antes de cada push.

---

## Estrutura

```
dataset/
  2026-08-04/
    eventos.jsonl        173 LogRecord, um por linha
    schema.json          formato, campos e atributos
    estatisticas.json    contagens, descartes e qualidade
    README.md            o que foi sanitizado nesta geração
scripts/
  verificar-append-only.sh
```

`dataset/<data>/README.md` descreve **aquela** geração. Este arquivo na raiz
descreve o repositório e é o único que muda com o tempo.

## O que tem dentro (snapshot 2026-08-04)

| Evento | Registros |
|---|---|
| `http_access` | 132 |
| `catalog_load` | 12 |
| `geo_lookup` | 8 |
| `history_persist` | 8 |
| `handshake` | 3 |
| `app_start` · `history_load` | 2 cada |
| `calc_request` · `calc_complete` · `divisao_calculada` · `dividir_por_prefixo` · `plano_vlan` · `vlan_plano_gerado` | 1 cada |

Descartados antes de publicar: **21** registros de ruído técnico (estáticos,
`/q/*`, `/web/*`, `/telemetria/api*`). **37** registros ficaram sem `traceId` de
correlação — está declarado em `estatisticas.json` em vez de escondido.

---

## Privacidade: o que foi removido e por quê

| Dado original | Tratamento | Motivo |
|---|---|---|
| IP do visitante | SHA-256 com sal secreto, truncado em 12 hex (`framework.field.ip_hash`) | Identifica pessoa. O sal fica no servidor e **nunca** entra neste repositório. Sendo estável, ainda permite contar visitantes únicos sem saber quem são. |
| Coordenadas GPS (`lat`/`lon`) | **Removidas** | Seis casas decimais são ~10 cm. Nem hash nem arredondamento tornam isso publicável. |
| Domínio consultado quando era um IP | Pseudonimizado como acima | Mesmo risco do IP. |
| Campo `body` | **Reconstruído** a partir dos atributos já sanitizados | Ele repetia os valores em texto livre (`evento=geo_lookup ip=...`); limpar só os atributos deixaria o dado sensível no texto. Este é o erro que quase passou. |

Endereços IPv4 de faixa **privada, loopback e documentação** permanecem: são os
valores de laboratório que os próprios usuários digitaram para estudar, não
identificadores de pessoas.

### Verificação independente

Antes do primeiro push, o arquivo final passou por uma varredura **externa ao
gerador** — porque instrumento que se autoavalia não é evidência independente.
Resultado nas 173 linhas:

```
IP público ............ 0
IPv6 .................. 0
Coordenada ............ 0
E-mail ................ 0
Hex longo (token) ..... 0
Cabeçalho sensível .... 0
CEP ................... 0   (6 falsos positivos: prefixo numérico de UUID)
```

**Limite honesto dessa varredura:** ela cobre padrões conhecidos. Não prova
ausência de dado sensível em formato não previsto — prova que estas classes não
aparecem. Resultado zero é hipótese, não teorema. Se você encontrar algo que
escapou, [abra uma issue](https://github.com/carmipa/framework-net-telemetry-dataset/issues)
que o snapshot é retirado e o problema documentado.

### Sobre a irreversibilidade do hash

O `ip_hash` é irreversível **porque o sal não é público**. Vale registrar o
limite: o espaço de IPv4 tem apenas ~4 bilhões de valores, então quem obtivesse o
sal conseguiria reverter os hashes por força bruta em pouco tempo. A proteção
está inteiramente no sigilo do sal, não no custo do hash.

---

## Como usar

```bash
# contar eventos por módulo
jq -r '.attributes[] | select(.key=="framework.module") | .value.stringValue' \
   dataset/2026-08-04/eventos.jsonl | sort | uniq -c | sort -rn

# rotas mais lentas
jq -r 'select(.attributes[]?.key=="framework.duration_ms")
       | [ (.attributes[]|select(.key=="http.route").value.stringValue),
           (.attributes[]|select(.key=="framework.duration_ms").value.stringValue) ]
       | @tsv' dataset/2026-08-04/eventos.jsonl | sort -k2 -rn | head
```

Em Python, cada linha é um objeto JSON independente — `json.loads` linha a linha,
sem carregar o arquivo inteiro.

## Como um snapshot novo é gerado

No servidor, a partir da telemetria corrente:

```bash
scripts/exportar-dataset.sh        # no repositório da aplicação
```

Ele sanitiza, audita e grava em `dataset/<data>/`. A pasta é copiada para cá,
**acrescentada** ao lado das anteriores, e passa pela mesma varredura
independente antes do push.

---

Desenvolvido por **Paulo André Carminati** · [github.com/carmipa](https://github.com/carmipa)
