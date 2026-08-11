#!/usr/bin/env bash
#
# Guarda de imutabilidade dos snapshots.
#
# PROPOSITO: um dataset publico serve para alguem citar, comparar e reproduzir.
# Se o conteudo de um snapshot ja publicado mudar, a citacao passa a apontar para
# outra coisa sem que ninguem seja avisado. A regra deste repositorio e simples:
# so se ACRESCENTA. Correcao de snapshot antigo se faz publicando um novo.
#
# INVARIANTE: nenhum arquivo sob dataset/<data>/ que ja exista em HEAD pode ser
# modificado (M), removido (D) ou renomeado (R). Arquivo novo (A) e livre.
#
# COMPORTAMENTO EM CASO DE FALHA: sai com codigo 1 listando exatamente quais
# arquivos violaram e o que aconteceu com cada um. Falha fechada: na duvida
# (nao e repositorio git, HEAD inexistente) tambem reprova, em vez de aprovar
# por nao conseguir verificar.
#
# USO:  bash scripts/verificar-append-only.sh
set -uo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERRO: nao estou dentro de um repositorio git." >&2
  exit 1
fi

# Repositorio recem-criado, sem nenhum commit ainda: nada a proteger.
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "OK: primeiro commit — nao existe snapshot anterior para proteger."
  exit 0
fi

# Compara o commit atual com a arvore de trabalho + area de stage.
violacoes="$(git diff HEAD --name-status -- dataset/ \
             | awk '$1 ~ /^(M|D|R)/ {print}')"

if [ -z "$violacoes" ]; then
  echo "OK: nenhum snapshot existente foi modificado ou removido."
  novos="$(git diff HEAD --name-status -- dataset/ | awk '$1 == "A" {print $2}' | wc -l | tr -d ' ')"
  [ "$novos" != "0" ] && echo "     $novos arquivo(s) novo(s) sendo acrescentado(s)."
  exit 0
fi

echo "REPROVADO: snapshot ja publicado foi alterado." >&2
echo >&2
echo "$violacoes" | while read -r estado arquivo resto; do
  case "$estado" in
    M*) motivo="MODIFICADO" ;;
    D*) motivo="REMOVIDO" ;;
    R*) motivo="RENOMEADO" ;;
    *)  motivo="$estado" ;;
  esac
  printf '  %-12s %s %s\n' "$motivo" "$arquivo" "$resto" >&2
done
echo >&2
echo "Snapshot publicado e fato historico. Para corrigir, publique um snapshot" >&2
echo "NOVO em dataset/<data>/ e explique a diferenca no README da raiz." >&2
exit 1
