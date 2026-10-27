#!/usr/bin/env bash
# Atualiza Fontes/ e Schemas/ a partir do SVN do ACBr (trunk2) e aplica os ajustes do Boa Gestão.
# Uso: ./atualiza.sh [revisão]   (sem revisão: HEAD). Depois: revisar o diff, commitar e fazer push;
# no monorepo boagestao/bg, gravar o commit novo em dfe/acbr.lock e rodar dfe/scripts/acbr.sh.
set -euo pipefail

ACBR_URL="http://svn.code.sf.net/p/acbr/code/trunk2"
REVISAO="${1:-HEAD}"
RAIZ=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Baixando Fontes ($REVISAO)..."
svn export --quiet --force -r "$REVISAO" "$ACBR_URL/Fontes" "$TMP/Fontes"

echo "Baixando Schemas ($REVISAO)..."
svn export --quiet --force -r "$REVISAO" "$ACBR_URL/Exemplos/ACBrDFe/Schemas" "$TMP/Schemas"

rsync -a --delete "$TMP/Fontes/" "$RAIZ/Fontes/"
rsync -a --delete "$TMP/Schemas/" "$RAIZ/Schemas/"

# DANFE da NF-e e da NFC-e com Arial no lugar de Times
echo "Substituindo a fonte Times por Arial no DANFE..."
for arquivo in \
    Fontes/ACBrDFe/ACBrNFe/DANFE/NFe/FPDF/ACBrNFeDANFeFPDF.pas \
    Fontes/ACBrDFe/ACBrNFe/DANFE/NFCe/FPDF/ACBrNFCeDANFeFPDF.pas; do
    if [ "$(uname)" = "Darwin" ]; then
        LC_ALL=C sed -i '' 's/Times/Arial/g' "$RAIZ/$arquivo"
    else
        sed -i 's/Times/Arial/g' "$RAIZ/$arquivo"
    fi
done

svn info --show-item last-changed-revision -r "$REVISAO" "$ACBR_URL" > "$RAIZ/REVISAO"
echo
echo "ACBr trunk2 r$(cat "$RAIZ/REVISAO") em Fontes/ e Schemas/. Revise com git status/diff e commite."
