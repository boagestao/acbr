# ACBr — dependências do DF-e do Boa Gestão

Fontes e schemas do [Projeto ACBr](https://projetoacbr.com.br/) (SVN `trunk2`), na revisão gravada em `REVISAO`, e as bibliotecas nativas usadas para compilar e rodar o serviço DF-e do monorepo [boagestao/bg](https://github.com/boagestao/bg) (`dfe/`).

- `Fontes/` — `trunk2/Fontes`
- `Schemas/` — `trunk2/Exemplos/ACBrDFe/Schemas`
- `Bibliotecas/` — bibliotecas nativas do DF-e, por plataforma (`x86_64`, `aarch64`, `win64`): `libsagui` (servidor HTTP do Brook) e, no Windows, as DLLs do OpenSSL, libxml2, libxslt e libiconv. Não vêm do ACBr e o `atualiza.sh` não mexe nelas.

Ajustes locais, aplicados pelo `atualiza.sh`:

- o DANFE da NF-e e da NFC-e (`ACBrNFeDANFeFPDF.pas`, `ACBrNFCeDANFeFPDF.pas`) usa Arial no lugar de Times;
- a NFS-e do Padrão Nacional (`PadraoNacional.LerXml.pas`) só lê `finNFSe` de `infDPS` quando a tag vem preenchida. Desde a r48805 (ACBR-9969) a leitura sem a tag, comum no layout anterior à NT 009 v1.01, gerava `Valor string inválido para TfinNFSe` depois da nota autorizada. O script falha se o trecho original não for encontrado: nesse caso, conferir se o ACBr corrigiu a leitura e remover o ajuste.

## Uso no monorepo

`dfe/acbr.lock` guarda o commit deste repositório usado pelo DF-e. `dfe/scripts/acbr.sh` (também chamado por `bun run setup` e pelo `build.sh` do DF-e) instala essa versão em `dfe/libs/acbr/` (`Fontes/`, `Schemas/` e `Bibliotecas/`), como o `bun install` faz com o `node_modules`.

## Atualização

1. `./atualiza.sh` (ou `./atualiza.sh <revisão>`), que precisa do `svn` e do `rsync`.
2. Revisar o diff, commitar como `ACBr trunk2 r<revisão>` e fazer push.
3. No monorepo, gravar o commit novo em `dfe/acbr.lock`, rodar `dfe/scripts/acbr.sh`, compilar o DF-e e commitar o lock junto com os ajustes de código.

## Licença

O ACBr é distribuído sob a LGPL; ver os cabeçalhos dos fontes e o site do projeto.
