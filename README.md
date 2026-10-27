# ACBr — cópia usada pelo Boa Gestão

Fontes e schemas do [Projeto ACBr](https://projetoacbr.com.br/) (SVN `trunk2`), na revisão gravada em `REVISAO`, usados para compilar o serviço DF-e do monorepo [boagestao/bg](https://github.com/boagestao/bg) (`dfe/`).

- `Fontes/` — `trunk2/Fontes`
- `Schemas/` — `trunk2/Exemplos/ACBrDFe/Schemas`

Ajuste local: o DANFE da NF-e e da NFC-e (`ACBrNFeDANFeFPDF.pas`, `ACBrNFCeDANFeFPDF.pas`) usa Arial no lugar de Times.

## Uso no monorepo

`dfe/acbr.lock` guarda o commit deste repositório usado pelo DF-e. `dfe/scripts/acbr.sh` (também chamado por `bun run setup` e pelo `build.sh` do DF-e) instala essa versão em `dfe/libs/acbr/Fontes` e `dfe/schemas`, como o `bun install` faz com o `node_modules`.

## Atualização

1. `./atualiza.sh` (ou `./atualiza.sh <revisão>`), que precisa do `svn` e do `rsync`.
2. Revisar o diff, commitar como `ACBr trunk2 r<revisão>` e fazer push.
3. No monorepo, gravar o commit novo em `dfe/acbr.lock`, rodar `dfe/scripts/acbr.sh`, compilar o DF-e e commitar o lock junto com os ajustes de código.

## Licença

O ACBr é distribuído sob a LGPL; ver os cabeçalhos dos fontes e o site do projeto.
