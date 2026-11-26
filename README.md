# ACBr — dependências do DF-e do Boa Gestão

Fontes e schemas do [Projeto ACBr](https://projetoacbr.com.br/) (SVN `trunk2`), na revisão gravada em `REVISAO`, e as bibliotecas nativas usadas para compilar e rodar o serviço DF-e do monorepo [boagestao/bg](https://github.com/boagestao/bg) (`dfe/`).

- `Fontes/` — `trunk2/Fontes`
- `Schemas/` — `trunk2/Exemplos/ACBrDFe/Schemas`
- `Bibliotecas/` — bibliotecas nativas do DF-e, por plataforma (`x86_64`, `aarch64`, `win64`): `libsagui` (servidor HTTP do Brook) e, no Windows, as DLLs do OpenSSL, libxml2, libxslt e libiconv. Não vêm do ACBr e o `atualiza.sh` não mexe nelas.

Ajustes locais, aplicados pelo `atualiza.sh`:

- o DANFE da NF-e (`ACBrNFeDANFeFPDF.pas` e o leiaute da Reforma Tributária, NT 2026.010, em `ACBrNFeDANFeFPDFRTC.pas`) e o da NFC-e (`ACBrNFCeDANFeFPDF.pas`) usam Arial no lugar de Times.
- no DANFE da Reforma Tributária (`ACBrNFeDANFeFPDFRTC.pas`), a caixa da chave de acesso e o valor de cada campo reduzem a fonte até caber (em retrato, a chave perdia os últimos dígitos com Arial, e nome, endereço, bairro e município longos perdiam o fim, com Arial ou Times), e o quadro de faturas, que imprime no máximo 24 duplicatas, avisa no título quando há mais ("FATURA / DUPLICATAS (24 DE n - DEMAIS NO XML)"). Nas linhas dos itens, ICMS e IBS/CBS aparecem sempre, zero incluído; IS e IPI só aparecem quando têm base, alíquota ou valor (a coluna das bases sobe as linhas seguintes, os pares "IBS UF / IPI" e "IBS MUN / IS" ficam só com o IBS, e o item perde a quarta linha quando nenhum dos dois aparece). O script falha se não achar os trechos: nesse caso, conferir se o ACBr mudou ou corrigiu o leiaute e rever os ajustes.

## Uso no monorepo

`dfe/acbr.lock` guarda o commit deste repositório usado pelo DF-e. `dfe/scripts/acbr.sh` (também chamado por `bun run setup` e pelo `build.sh` do DF-e) instala essa versão em `dfe/libs/acbr/` (`Fontes/`, `Schemas/` e `Bibliotecas/`), como o `bun install` faz com o `node_modules`.

## Atualização

1. `./atualiza.sh` (ou `./atualiza.sh <revisão>`), que precisa do `svn` e do `rsync`.
2. Revisar o diff, commitar como `ACBr trunk2 r<revisão>` e fazer push.
3. No monorepo, gravar o commit novo em `dfe/acbr.lock`, rodar `dfe/scripts/acbr.sh`, compilar o DF-e e commitar o lock junto com os ajustes de código.

## Licença

O ACBr é distribuído sob a LGPL; ver os cabeçalhos dos fontes e o site do projeto.
