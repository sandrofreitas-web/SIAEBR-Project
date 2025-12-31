
-- =====================
-- CREATE STAGING TABLE
-- =====================

CREATE TABLE stg_BOQ_Customers (
    -- Chave técnica
    id_boq INT IDENTITY(1,1) PRIMARY KEY,

    -- Controle do arquivo BOQ
    id_conciliacao        VARCHAR(50)  NOT NULL,
    chave_enlace          VARCHAR(50)  NULL,
    -- Identificadores
    wbs                   VARCHAR(50)  NULL,
    siae_id               VARCHAR(50)  NULL,
    enlace                VARCHAR(100) NULL,
    id_atividade          VARCHAR(100)  NULL,
    nome_arquivo_boq      VARCHAR(255) NULL,
    grupo_usuarios        VARCHAR(50)  NULL,
    descr_lote_boq        VARCHAR(100) NULL,
    status_linha_boq      VARCHAR(50)  NULL,
    ano_orcamentario      VARCHAR(50)  NULL,
    site_nms              VARCHAR(100) NULL,
    -- Endereços / Localização
    end_id_de             VARCHAR(50)  NULL,
    end_id_para           VARCHAR(50)  NULL,
    id_estado             VARCHAR(50)  NULL,
    id_regional           VARCHAR(50)  NULL,
    id_cidade             VARCHAR(50)  NULL,
    -- Contrato / LPU
    contrato_descricao    VARCHAR(255) NULL,
    id_contrato           VARCHAR(50)  NULL,
    id_lpu                VARCHAR(50)  NULL,
    cod_sap_cliente       VARCHAR(50)  NULL,
    id_material_tipo      VARCHAR(50)  NULL,
    -- Valores LPU
    valor_unit_net        VARCHAR(50) NULL,
    valor_unit_boq        VARCHAR(50) NULL,
    qty                   VARCHAR(50)  NULL,
    -- Pedido
    pedido                VARCHAR(50)  NULL,
    item_pedido           VARCHAR(50)  NULL,
    data_pedido           VARCHAR(50)  NULL,
    --Valores PO
    valor_total_net       VARCHAR(50) NULL,
    valor_total_boq       VARCHAR(50) NULL,
    -- Auditoria
    data_carga            DATETIME NOT NULL DEFAULT GETDATE()
);

-- =====================
-- CREATE BOQ TABLE
-- =====================

CREATE TABLE SIAEBR_Sales.BOQ_Customres (
    -- Chave técnica
    id_boq INT IDENTITY(1,1) PRIMARY KEY,

    -- Identificadores
    wbs                   VARCHAR(50)  NULL,
    siae_id               VARCHAR(50)  NULL,
    id_atividade          VARCHAR(100)  NULL,

    -- Controle do arquivo BOQ
    id_conciliacao        VARCHAR(50)  NOT NULL,
    chave_enlace          VARCHAR(50)  NULL,
    nome_arquivo_boq      VARCHAR(255) NULL,
    grupo_usuarios        VARCHAR(50)  NULL,
    descr_lote_boq        VARCHAR(100) NULL,
    status_linha_boq      VARCHAR(50)  NULL,
    ano_orcamentario      INT          NULL,
    site_nms              VARCHAR(100) NULL,
    enlace                VARCHAR(100) NULL,

    -- Endereços / Localização
    end_id_de             VARCHAR(50)  NULL,
    end_id_para           VARCHAR(50)  NULL,
    id_estado             VARCHAR(50)  NULL,
    id_regional           VARCHAR(50)  NULL,
    id_cidade             VARCHAR(50)  NULL,

    -- Contrato / LPU
    contrato_descricao    VARCHAR(255) NULL,
    id_contrato           VARCHAR(50)  NULL,
    id_lpu                VARCHAR(50)  NULL,
    cod_sap_cliente       VARCHAR(50)  NULL,
    id_material_tipo      VARCHAR(50)  NULL,

    -- Valores LPU
    
    valor_unit_net        decimal(18, 2),
    valor_unit_boq        decimal(18, 2),
    
    -- Pedido
    pedido                VARCHAR(50)  NULL,
    item_pedido           VARCHAR(50)  NULL,
    data_pedido           DATE         NULL,
    qty                   int NULL,
        
    --Valores PO
    
    valor_total_net       decimal(18, 2),
    valor_total_boq       decimal(18, 2),

    -- Auditoria
    data_carga            DATETIME
    );

    */


-- ====================
-- PROCEDURE LOAD
-- ====================

create or alter procedure dbo.prc_boq_Customers
(
    @file_adress varchar(500)
)
as
begin
    set NOCOUNT on;

    begin TRY
        -- 1. Clean Staging
        truncate table dbo.stg_BOQ_Customers;
        -- 2. CSV Load
        declare @sql nvarchar(max);
    
        set @sql = '
        bulk insert dbo.stg_BOQ_Customers
        from ''' + @file_adress + '''
        with (
            firstrow = 2,
            fieldterminator = '';'',
            codepage = ''65001'',
            tablock
        );';

        exec sys.sp_executesql @sql
        
        -- 3. Data Validation
        if exists (
            select 1
            from dbo.stg_BOQ_Customers
            where valor_total_boq is null
                or valor_total_net is null
                or valor_unit_boq is null
                or valor_unit_net is null
                or valor_total_boq like '%[^0-9.,]%'
                or valor_total_net like '%[^0-9.,]%'
                or valor_unit_boq like '%[^0-9.,]%'
                or valor_unit_net like '%[^0-9.,]%'
        )
        begin
            throw 50001, 'STAGING Values Error.' , 1;
        end;

        -- 4. Load Final Table
        insert into SIAEBR_Sales.BOQ_Customres
            (
            -- Chave técnica
           -- id_boq,
            -- Identificadores
            wbs,
            siae_id,
            id_atividade,
            -- Controle do arquivo BOQ
            id_conciliacao,
            chave_enlace,
            nome_arquivo_boq,
            grupo_usuarios,
            descr_lote_boq,
            status_linha_boq,
            ano_orcamentario,
            site_nms,
            enlace,
            -- Endereços / Localização
            end_id_de,
            end_id_para,
            id_estado,
            id_regional,
            id_cidade,
            -- Contrato / LPU
            contrato_descricao,
            id_contrato,
            id_lpu,
            cod_sap_cliente,
            id_material_tipo,
            -- Valores LPU    
            valor_unit_net,
            valor_unit_boq,
            -- Pedido
            pedido,
            item_pedido,
            data_pedido,
            qty,
            --Valores PO
            valor_total_net,
            valor_total_boq,
            -- Auditoria
            data_carga
        )
        select
            -- Chave técnica
           -- id_boq,
            -- Identificadores
            wbs,
            siae_id,
            id_atividade,
            -- Controle do arquivo BOQ
            id_conciliacao,
            chave_enlace,
            nome_arquivo_boq,
            grupo_usuarios,
            descr_lote_boq,
            status_linha_boq,
            ano_orcamentario,
            site_nms,
            enlace,
            -- Endereços / Localização
            end_id_de,
            end_id_para,
            id_estado,
            id_regional,
            id_cidade,
            -- Contrato / LPU
            contrato_descricao,
            id_contrato,
            id_lpu,
            cod_sap_cliente,
            id_material_tipo,
            -- Valores LPU    
            CAST(REPLACE(valor_unit_net,',','.') AS DECIMAL(18,2)),
            CAST(REPLACE(valor_unit_boq,',','.') AS DECIMAL(18,2)),
            -- Pedido
            pedido,
            item_pedido,
            CONVERT(DATE, data_pedido, 103),
            qty,
            --Valores PO
            CAST(REPLACE(valor_total_net,',','.') AS DECIMAL(18,2)),
            CAST(REPLACE(valor_total_boq,',','.') AS DECIMAL(18,2)),
            -- Auditoria
            data_carga
        from dbo.stg_BOQ_Customers;

end try
begin catch
    -- Error Check
    declare
        @msg nvarchar(4000),
        @num int,
        @sev int,
        @sta int;

    select
        @msg = ERROR_MESSAGE(),
        @num = ERROR_NUMBER(),
        @sev = ERROR_SEVERITY();
      --  @sta = ERROR_STATE;

    raiserror (
        'Load Fault Msg: %s',
        @sev,
        @sta,
        @msg
       );
    end catch
end;


exec dbo.prc_boq_Customers
    @file_adress = 'C:\Users\salmeida\Documents\GitHub\DEV_SIAEBR\09. SIAEBR\clientes_boq_W52.csv'


