INSERT INTO Impressoes_Modelos
(
    Modulo, ModuloApp, Ordem, ModuloAmigavel, NomeRelatorio,
    ImprimirDireto, NomeRelatorio_Amigavel, Padrao, Acao,
    LojaOrigem, Desativado, RegraDeValidacao, ControlesJson,
    PreCadastrado, CriterioParaExibir, MessengerJson, Vias
)
VALUES
(

    'PEDIDO_DUPLICATA',
    'TODOS',
    6,
    'Venda',
    'Duplicata_PROMISSORIA',
    0,
    'Promissoria',
    0,
    'Util_Report_Open([NomeRelatorio],[ImprimirDireto],''[Código da Venda]='' & [Forms].[Vendas3].[Código da Venda])',
    Null,
    0,
    Null,
    Null,
    -1,
    Null,
    '{""tipo"":""cliente"", ""expr"":""Forms!Vendas3![nome do cliente]""}',
    1
);
