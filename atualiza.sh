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

# Nos itens do DANFE RTC, IS e IPI só aparecem quando têm base, alíquota ou valor (o IPI só a indústria destaca); ICMS
# e IBS/CBS aparecem sempre, zero incluído. A coluna das bases sobe as linhas seguintes, o par "IBS UF / IPI" e o par
# "IBS MUN / IS" ficam só com o IBS, e o item perde a quarta linha quando IS e IPI não aparecem.
echo "Omitindo IS e IPI zerados nos itens do DANFE RTC..."
read -r -d '' AJUSTE_TRIBUTOS_ITEM <<'PERL' || true
my $nl = /\r\n/ ? "\r\n" : "\n";
my $aux = <<'PAS';
// Boa Gestao: IS e IPI so aparecem no item quando tem base, aliquota ou valor; ICMS e IBS/CBS aparecem sempre,
// zero incluido. O tributo omitido fica com rotulo vazio.
procedure OmitirTributosZeradosRTC(var AItem: TACBrNFeDANFeRTCItem);
begin
  if (AItem.Bases[2].Valor = 0) and (AItem.Aliquotas[2, 1].Valor = 0) and (AItem.Valores[2, 1].Valor = 0) then
  begin
    AItem.Bases[2].Rotulo := '';
    AItem.Aliquotas[2, 1].Rotulo := '';
    AItem.Valores[2, 1].Rotulo := '';
  end;

  if (AItem.Bases[3].Valor = 0) and (AItem.Aliquotas[1, 1].Valor = 0) and (AItem.Valores[1, 1].Valor = 0) then
  begin
    AItem.Bases[3].Rotulo := '';
    AItem.Aliquotas[1, 1].Rotulo := '';
    AItem.Valores[1, 1].Rotulo := '';
  end;
end;

function LinhasTributosRTC(AItem: TACBrNFeDANFeRTCItem): Integer;
var
  I: Integer;
begin
  OmitirTributosZeradosRTC(AItem);
  Result := 0;
  for I := Low(AItem.Bases) to High(AItem.Bases) do
    if AItem.Bases[I].Rotulo <> '' then
      Inc(Result);
  Result := Max(Result, High(TACBrNFeDANFeRTCPares) + 1);
end;

PAS
$aux =~ s/\n/$nl/g;
$n1 += s{^(procedure TBlocoItensRTC\.PrepararItem\()}{$aux$1}m;
$n2 += s{LAlturaTributos := \(High\(TACBrNFeDANFeRTCBases\) \+ 1\) \* LAltura55;}{LAlturaTributos := LinhasTributosRTC(Report.RTC.Item(AIndex)) * LAltura55;};
$n3 += s{(procedure TBlocoItensRTC\.DesenharItem\([^)]*\);\r?\nvar\r?\n\h*)I: Integer;}{${1}I, J: Integer;};
$n4 += s{^(\h*)(LItem := LRTC\.Item\(AIndex\);)(\r?\n)}{$1$2$3$1OmitirTributosZeradosRTC(LItem);$3}m;
$n5 += s{^(\h*)for I := Low\(LItem\.Bases\) to High\(LItem\.Bases\) do\r?\n\h*(APDF\.TextBox\(FX\[5\] \+ 0\.5, LY \+ )\(I \* LAltura\)(, LW, LAltura,)\r?\n\h*(Pontilhado\(APDF, LItem\.Bases\[I\]\.Rotulo, LRTC\.FormatarValor\(LItem\.Bases\[I\]\.Valor\), LW\), 'T', 'L',)\r?\n\h*(False, False, False\);)\r?\n}{
    join($nl, "$1J := 0;", "$1for I := Low(LItem.Bases) to High(LItem.Bases) do", "$1  if LItem.Bases[I].Rotulo <> '' then",
      "$1  begin", "$1    $2(J * LAltura)$3", "$1      $4", "$1      $5", "$1    Inc(J);", "$1  end;") . $nl
}me;
$n6 += s{^(\h*)(LTexto := LValores\[0\]) (\+ cSeparador \+ LValores\[1\];)(\r?\n)}{$1if APares[I, 1].Rotulo = '' then$4$1  $2$4$1else$4$1  $2 $3$4}m;
END { exit(($n1 == 1 && $n2 == 1 && $n3 == 1 && $n4 == 1 && $n5 == 1 && $n6 == 1) ? 0 : 1) }
PERL
perl -0777 -pi -e "$AJUSTE_TRIBUTOS_ITEM" "$RTC" || {
    echo "Omissão de IS e IPI zerados não aplicada em ACBrNFeDANFeFPDFRTC.pas: revisar se o ACBr mudou o quadro dos itens." >&2
    exit 1
}

svn info --show-item last-changed-revision -r "$REVISAO" "$ACBR_URL" > "$RAIZ/REVISAO"
echo
echo "ACBr trunk2 r$(cat "$RAIZ/REVISAO") em Fontes/ e Schemas/. Revise com git status/diff e commite."
