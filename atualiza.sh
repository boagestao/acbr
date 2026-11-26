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
    Fontes/ACBrDFe/ACBrNFe/DANFE/NFe/FPDF/ACBrNFeDANFeFPDFRTC.pas \
    Fontes/ACBrDFe/ACBrNFe/DANFE/NFCe/FPDF/ACBrNFCeDANFeFPDF.pas; do
    if [ "$(uname)" = "Darwin" ]; then
        LC_ALL=C sed -i '' 's/Times/Arial/g' "$RAIZ/$arquivo"
    else
        sed -i 's/Times/Arial/g' "$RAIZ/$arquivo"
    fi
done

# DANFE da Reforma Tributária (NT 2026.010): com Arial (mais largo que a Times do leiaute original) a chave de acesso
# perdia os últimos dígitos em retrato. Liga o ajuste de fonte do próprio TextBox na caixa da chave.
RTC="$RAIZ/Fontes/ACBrDFe/ACBrNFe/DANFE/NFe/FPDF/ACBrNFeDANFeFPDFRTC.pas"
echo "Ajustando a fonte da chave de acesso no DANFE RTC..."
perl -0777 -pi -e '
    $n += s{(FormatarChaveAcesso\(NFe\.infNFe\.ID\), \x27T\x27, \x27C\x27,\r?\n\h*False, False, )False\);}{${1}True);};
    END { exit($n == 1 ? 0 : 1) }
' "$RTC" || {
    echo "Ajuste da chave de acesso não aplicado em ACBrNFeDANFeFPDFRTC.pas: revisar se o ACBr mudou o trecho." >&2
    exit 1
}

# Os demais campos do DANFE RTC cortavam letras do fim em texto longo (nome, endereço, bairro e município com até 60
# caracteres, em Arial ou em Times): o valor de cada campo também reduz a fonte até caber.
echo "Ajustando a fonte dos campos do DANFE RTC..."
perl -0777 -pi -e '
    $n += s{(AValor, \x27B\x27, AAlinhamento,\r?\n\h*False, False, )False\);}{${1}True);};
    END { exit($n == 1 ? 0 : 1) }
' "$RTC" || {
    echo "Ajuste dos campos não aplicado em ACBrNFeDANFeFPDFRTC.pas: revisar se o ACBr mudou o DesenharCampo." >&2
    exit 1
}

# O quadro Fatura/Duplicatas do DANFE RTC imprime no máximo 24 duplicatas (8 linhas de 3); o XML leva todas. Com mais
# de 24, o título avisa que as demais estão só no XML, em vez de omiti-las em silêncio.
echo "Avisando no DANFE RTC as duplicatas que não cabem no quadro..."
perl -0777 -pi -e '
    $n += s{^(\h*)Titulo\(LPDF, 0, 1, Width, \x27FATURA / DUPLICATAS\x27\);(\r?\n)}{${1}if NFe.Cobr.Dup.Count > FLinhas * cDuplicatasPorLinha then$2${1}  Titulo(LPDF, 0, 1, Width, \x27FATURA / DUPLICATAS (\x27 + IntToStr(FLinhas * cDuplicatasPorLinha) + \x27 DE \x27 +$2${1}    IntToStr(NFe.Cobr.Dup.Count) + \x27 - DEMAIS NO XML)\x27)$2${1}else$2${1}  Titulo(LPDF, 0, 1, Width, \x27FATURA / DUPLICATAS\x27);$2}m;
    END { exit($n == 1 ? 0 : 1) }
' "$RTC" || {
    echo "Aviso das duplicatas não aplicado em ACBrNFeDANFeFPDFRTC.pas: revisar se o ACBr mudou o quadro de faturas." >&2
    exit 1
}

svn info --show-item last-changed-revision -r "$REVISAO" "$ACBR_URL" > "$RAIZ/REVISAO"
echo
echo "ACBr trunk2 r$(cat "$RAIZ/REVISAO") em Fontes/ e Schemas/. Revise com git status/diff e commite."
