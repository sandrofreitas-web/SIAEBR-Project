-- ============================================================
-- SIAEBR PMO - SQL Server Schema
-- Camada de dados: substitui Power Query + MS Access
-- ============================================================

-- CREATE DATABASE SIAEBR_PMO COLLATE Latin1_General_CI_AS

USE SIAEBR_PMO;
GO

-- ============================================================
-- 1. ANALISE_PMO  (origem: MS Access - Analise_PMO)
-- Tabela central de projetos / WBS
-- ============================================================
CREATE TABLE dbo.ANALISE_PMO (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    SIAE_ID                 NVARCHAR(50)    NOT NULL,
    WBS                     NVARCHAR(50)    NOT NULL,
    WBS_Locked              BIT             DEFAULT 0,
    DE                      NVARCHAR(50)    NULL,
    PARA                    NVARCHAR(50)    NULL,
    CHAVE_CLIENTE           NVARCHAR(30)    NULL,
    CLIENTE                 NVARCHAR(100)   NULL,
    ANO                     SMALLINT        NULL,
    CONTRATO                NVARCHAR(50)    NULL,
    Regional                NVARCHAR(10)    NULL,
    UF                      CHAR(2)         NULL,
    META                    NVARCHAR(50)    NULL,
    LOS_Final_Data          DATE            NULL,
    Vistoria_Final_Data     DATE            NULL,
    MOS_Final_Data          DATE            NULL,
    Instalacao_Final_Data   DATE            NULL,
    CheckList_Final_Data    DATE            NULL,
    Total_SUB_Service       DECIMAL(18,2)   DEFAULT 0,
    PDF_SUB_Service         DECIMAL(18,2)   DEFAULT 0,
    FIELD_COST              DECIMAL(18,2)   DEFAULT 0,
    RAZAO_MATERIAL_WBS      DECIMAL(18,2)   DEFAULT 0,
    TRSNP_VALUE_WBS         DECIMAL(18,2)   DEFAULT 0,
    Net_Order_HW            DECIMAL(18,2)   DEFAULT 0,
    Net_Order_SV            DECIMAL(18,2)   DEFAULT 0,
    Valor_Faturado          DECIMAL(18,2)   DEFAULT 0,
    Billed_Delta            DECIMAL(18,2)   DEFAULT 0,
    WBS_STATUS              NVARCHAR(30)    NULL,
    WBS_CONCILIACAO         NVARCHAR(50)    NULL,
    DATA_CONCILIACAO        DATE            NULL,
    PROJETO_CONCILIACAO     NVARCHAR(50)    NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE(),
    CONSTRAINT UQ_ANALISE_PMO_SIAEOD UNIQUE (SIAE_ID)
);
GO

CREATE INDEX IX_ANALISE_PMO_WBS       ON dbo.ANALISE_PMO (WBS);
CREATE INDEX IX_ANALISE_PMO_STATUS    ON dbo.ANALISE_PMO (WBS_STATUS);
CREATE INDEX IX_ANALISE_PMO_CLIENTE   ON dbo.ANALISE_PMO (CLIENTE);
GO

-- ============================================================
-- 2. ZSD210  (origem: SAP extrato ZSD210 - Invoices)
-- ============================================================

DROP TABLE IF EXISTS dbo.ZSD210;

CREATE TABLE dbo.ZSD210 (
    SO_Item                 DECIMAL(18,3) PRIMARY KEY,
    Sales_Document          NVARCHAR(20)    NULL,
    Item                    NVARCHAR(10)    NULL,
    Material                NVARCHAR(50)    NULL,
    Material_Description    NVARCHAR(200)   NULL,
    Order_Qty               DECIMAL(18,3)   NULL,
    Document_Date           DATE            NULL,
    Sales_Document_Type     NVARCHAR(10)    NULL,
    Schedule_Line_Date      DATE            NULL,
    Customer               NVARCHAR(20)    NULL,
    Name1                   NVARCHAR(200)   NULL,
    PO_Number               NVARCHAR(50)    NULL,
    Purchase_Order_Date     DATE            NULL,
    Purchase_Order_Item     NVARCHAR(10)    NULL,
    WBS_Element             NVARCHAR(50)    NULL,
    Marking_Link_ID         NVARCHAR(50)    NULL,
    Sales_Order_Status      NVARCHAR(5)     NULL,
    Net_Value               DECIMAL(18,2)   NULL,
    Bill_Val                DECIMAL(18,2)   NULL,
    Delta_Bill              DECIMAL(18,2)   NULL,
    Tax_Amount              DECIMAL(18,2)   NULL,
    Order_Total             DECIMAL(18,2)   NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE()
);
GO

CREATE INDEX IX_ZSD210_WBS            ON dbo.ZSD210 (WBS_Element);
CREATE INDEX IX_ZSD210_Marking_Link_ID ON dbo.ZSD210 (Marking_Link_ID);
CREATE INDEX IX_ZSD210_DOC_DATE       ON dbo.ZSD210 (Document_Date);
CREATE INDEX IX_ZSD210_CUSTOMER       ON dbo.ZSD210 (Customer);
GO

-- ============================================================
-- 2.1 staging.ZSD210  (origem: SAP extrato ZSD210 - Invoices)
-- ============================================================

DROP TABLE IF EXISTS staging.ZSD210;

CREATE TABLE staging.ZSD210 (
    SO_Item                 NVARCHAR(50)    NULL,
    Sales_Document          NVARCHAR(20)    NULL,
    Item                    NVARCHAR(10)    NULL,
    Material                NVARCHAR(50)    NULL,
    Material_Description    NVARCHAR(200)   NULL,
    Order_Qty               NVARCHAR(20)    NULL,
    Document_Date           NVARCHAR(20)    NULL,
    Sales_Document_Type     NVARCHAR(10)    NULL,
    Schedule_Line_Date      NVARCHAR(20)    NULL,
    Customer                NVARCHAR(20)    NULL,
    Name1                   NVARCHAR(200)   NULL,
    PO_Number               NVARCHAR(100)    NULL,
    Purchase_Order_Date     NVARCHAR(20)    NULL,
    Purchase_Order_Item     NVARCHAR(10)    NULL,
    WBS_Element             NVARCHAR(50)    NULL,
    Marking_Link_ID         NVARCHAR(50)    NULL,
    Sales_Order_Status      NVARCHAR(30)    NULL,
    Net_Value               NVARCHAR(30)    NULL,
    Bill_Val                NVARCHAR(30)    NULL,
    Delta_Bill              NVARCHAR(30)    NULL,
    Tax_Amount              NVARCHAR(30)    NULL,
    Order_Total             NVARCHAR(30)    NULL,
    );
GO


-- ============================================================
-- 2.2 BULK INSERT — staging.ZSD210
-- ============================================================
-- Fonte: ID Num Services.xlsx exportado como CSV UTF-8
-- ============================================================
TRUNCATE TABLE staging.ZSD210;
BULK INSERT staging.ZSD210
FROM 'C:\Users\salmeida\Documents\00. Dep_PMO\00. PMO_SIAEBR\01. DB_SIAEBR\ZSD210\ZSD210.csv'
WITH (
   -- DATA_SOURCE         = N'',           -- remover se não usar external data source
   -- FORMAT              = 'CSV',
    FIRSTROW            = 2,             -- pula cabeçalho
    FIELDTERMINATOR     = ';',
    ROWTERMINATOR       = '\n',
    CODEPAGE            = '65001',       -- UTF-8
    TABLOCK
    );
GO

-- ============================================================
-- 2.4 EXECUTAR PROCEDURE dbo.sp_carga_ZSD210
-- ============================================================

TRUNCATE TABLE dbo.ZSD210;

-- Executar carga com valores padrão (trunca staging após sucesso)
EXEC dbo.sp_carga_ZSD210;

-- Sem truncar staging e com limite de 50 erros
EXEC dbo.sp_carga_ZSD210 
    @p_truncate_staging = 0,
    @p_max_errors = 50;


-- ============================================================
-- 2.3 Created by GitHub Copilot in SSMS - review carefully before executing
-- Procedure para validar, transformar e carregar dados de staging.ZSD210 para dbo.ZSD210
-- Inclui conversão de tipos, validação de dados e logging de ETL
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_carga_ZSD210
    @p_truncate_staging BIT = 1,  -- 1 = limpa staging após sucesso
    @p_max_errors INT = 100       -- máximo de erros permitidos
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @v_inicio DATETIME2 = GETDATE();
    DECLARE @v_registros_lidos INT = 0;
    DECLARE @v_registros_ok INT = 0;
    DECLARE @v_registros_erro INT = 0;
    DECLARE @v_status NVARCHAR(20) = 'RUNNING';
    DECLARE @v_mensagem NVARCHAR(1000);
    DECLARE @v_id_log INT;
    
    BEGIN TRY
        -- 1. Registrar início da carga
        INSERT INTO dbo.ETL_CARGA_LOG (tabela, fonte, dt_inicio, status)
        VALUES ('ZSD210', 'staging.ZSD210', @v_inicio, @v_status);
        
        SET @v_id_log = SCOPE_IDENTITY();
        
        -- 2. Contar registros no staging
        SELECT @v_registros_lidos = COUNT(*) FROM staging.ZSD210;
        
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ZSD210 — INICIADO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Registros no staging: ' + CAST(@v_registros_lidos AS VARCHAR);
        
        -- 3. Validação básica
        IF @v_registros_lidos = 0
        BEGIN
            SET @v_mensagem = 'Nenhum registro encontrado em staging.ZSD210';
            RAISERROR(@v_mensagem, 16, 1);
        END;
        
        -- 4. Inserir dados com conversão de tipos
        INSERT INTO dbo.ZSD210 (
            SO_Item, Sales_Document, Item, Material, Material_Description,
            Order_Qty, Document_Date, Sales_Document_Type, Schedule_Line_Date,
            Customer, Name1, PO_Number, Purchase_Order_Date, Purchase_Order_Item,
            WBS_Element, Marking_Link_ID, Sales_Order_Status, Net_Value, Bill_Val,
            Delta_Bill, Tax_Amount, Order_Total
        )
        SELECT
            TRY_CAST(SO_Item AS DECIMAL(18,3)),
            Sales_Document,
            Item,
            Material,
            Material_Description,
            TRY_CAST(Order_Qty AS DECIMAL(18,3)),
            TRY_CAST(Document_Date AS DATE),
            Sales_Document_Type,
            TRY_CAST(Schedule_Line_Date AS DATE),
            Customer,
            Name1,
            PO_Number,
            TRY_CAST(Purchase_Order_Date AS DATE),
            Purchase_Order_Item,
            WBS_Element,
            Marking_Link_ID,
            Sales_Order_Status,
            TRY_CAST(Net_Value AS DECIMAL(18,2)),
            TRY_CAST(Bill_Val AS DECIMAL(18,2)),
            TRY_CAST(Delta_Bill AS DECIMAL(18,2)),
            TRY_CAST(Tax_Amount AS DECIMAL(18,2)),
            TRY_CAST(Order_Total AS DECIMAL(18,2))
        FROM staging.ZSD210
        WHERE SO_Item IS NOT NULL
          AND TRY_CAST(SO_Item AS DECIMAL(18,3)) IS NOT NULL;
        
        SET @v_registros_ok = @@ROWCOUNT;
        SET @v_registros_erro = @v_registros_lidos - @v_registros_ok;
        
        -- 5. Validação de erros
        IF @v_registros_erro > @p_max_errors
        BEGIN
            SET @v_mensagem = 'Erros de validação excedem o limite: ' + CAST(@v_registros_erro AS VARCHAR);
            RAISERROR(@v_mensagem, 16, 1);
        END;
        
        -- 6. Limpar staging se solicitado
        IF @p_truncate_staging = 1
        BEGIN
            TRUNCATE TABLE staging.ZSD210;
            PRINT 'Tabela staging.ZSD210 truncada.';
        END;
        
        -- 7. Atualizar log com sucesso
        SET @v_status = 'OK';
        UPDATE dbo.ETL_CARGA_LOG
        SET dt_fim = GETDATE(),
            registros_lidos = @v_registros_lidos,
            registros_ok = @v_registros_ok,
            status = @v_status,
            mensagem = 'Carga concluída com sucesso'
        WHERE id = @v_id_log;
        
        -- 8. Relatório final
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ZSD210 — SUCESSO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Total registros lidos: ' + CAST(@v_registros_lidos AS VARCHAR);
        PRINT 'Registros inseridos: ' + CAST(@v_registros_ok AS VARCHAR);
        PRINT 'Registros com erro: ' + CAST(@v_registros_erro AS VARCHAR);
        PRINT 'Tempo de execução: ' + CAST(DATEDIFF(SECOND, @v_inicio, GETDATE()) AS VARCHAR) + ' segundos';
        PRINT '═══════════════════════════════════════════════════════';
        
    END TRY
    BEGIN CATCH
        SET @v_status = 'ERROR';
        SET @v_mensagem = ERROR_MESSAGE();
        
        -- Atualizar log com erro
        UPDATE dbo.ETL_CARGA_LOG
        SET dt_fim = GETDATE(),
            registros_lidos = @v_registros_lidos,
            registros_ok = @v_registros_ok,
            status = @v_status,
            mensagem = @v_mensagem
        WHERE id = @v_id_log;
        
        -- Relatório de erro
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ZSD210 — ERRO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Mensagem: ' + @v_mensagem;
        PRINT 'Registros processados: ' + CAST(@v_registros_ok AS VARCHAR) + '/' + CAST(@v_registros_lidos AS VARCHAR);
        PRINT '═══════════════════════════════════════════════════════';
        
        RAISERROR(@v_mensagem, 16, 1);
    END CATCH;
END;
GO

-- ============================================================
-- 3. ID_NUM_SERVICES  (origem: MS Access - ID Num Services)
-- POs de Fornecedores / Subcontratados
-- ============================================================

DROP TABLE IF EXISTS dbo.ID_NUM_SERVICES;

CREATE TABLE dbo.ID_NUM_SERVICES (
    id                      DECIMAL(18,3) PRIMARY KEY,
    Projeto                 NVARCHAR(50)    NULL,
    ID_ITEM                 NVARCHAR(10)    NULL,
    Cod_For_SAP             NVARCHAR(20)    NULL,
    Fornecedor              NVARCHAR(200)   NULL,
    LINK_SIAE_ID            NVARCHAR(50)    NULL,
    WBS_SAP                 NVARCHAR(50)    NULL,
    CodePro                 NVARCHAR(20)    NULL,
    Description             NVARCHAR(500)   NULL,
    Qty                     DECIMAL(18,3)   NULL,
    Value_Serv              DECIMAL(18,2)   NULL,
    Req_PO_D                DATE            NULL,
    PO_Number               NVARCHAR(30)    NULL,
    Issue_Date              DATE            NULL,
    Note                    NVARCHAR(500)   NULL,
    Owner                   NVARCHAR(100)   NULL,
    Status                  NVARCHAR(50)    NULL,
    OK                      BIT             NULL,
    Data_Aprovacao          DATE            NULL,
    Liberado_Pagto_80       DATE            NULL,
    lpp80sent               BIT             NULL,
    lpp80DocNumber          NVARCHAR(20)    NULL,
    pmoApproval80           BIT             NULL,
    Liberado_Pagto_20       DATE            NULL,
    lpp20sent               BIT             NULL,
    lpp20DocNumber          NVARCHAR(20)    NULL,
    pmoApproval20           BIT             NULL,
    sapMigo                 BIT             NULL,
    UF                      CHAR(2)         NULL,
    Regional                NVARCHAR(10)    NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE()
);
GO

CREATE INDEX IX_IDS_SIAE_ID           ON dbo.ID_NUM_SERVICES (LINK_SIAE_ID);
CREATE INDEX IX_IDS_WBS_SAP           ON dbo.ID_NUM_SERVICES (WBS_SAP);
CREATE INDEX IX_IDS_PO_NUMBER         ON dbo.ID_NUM_SERVICES (PO_Number);
CREATE INDEX IX_IDS_STATUS            ON dbo.ID_NUM_SERVICES (Status);
GO

-- ==================================================================
-- 3.1 Staging.ID_NUM_SERVICES  (origem: MS Access - ID Num Services)
-- POs de Fornecedores / Subcontratados
-- ==================================================================

DROP TABLE IF EXISTS staging.ID_NUM_SERVICES;

CREATE TABLE staging.ID_NUM_SERVICES (
    id                      NVARCHAR(50)    NULL,
    Projeto                 NVARCHAR(50)    NULL,
    ID_ITEM                 NVARCHAR(20)    NULL,
    Cod_For_SAP             NVARCHAR(20)    NULL,
    Fornecedor              NVARCHAR(200)   NULL,
    LINK_SIAE_ID            NVARCHAR(50)    NULL,
    WBS_SAP                 NVARCHAR(50)    NULL,
    CodePro                 NVARCHAR(20)    NULL,
    Description             NVARCHAR(500)   NULL,
    Qty                     NVARCHAR(50)    NULL,
    Value_Serv              nvarchar(50)    NULL,
    Req_PO_D                nvarchar(50)    NULL,
    PO_Number               NVARCHAR(30)    NULL,
    Issue_Date              NVARCHAR(50)    NULL,
    Note                    NVARCHAR(500)   NULL,
    Owner                   NVARCHAR(100)   NULL,
    Status                  NVARCHAR(50)    NULL,
    OK                      NVARCHAR(50)    NULL,
    Data_Aprovacao          NVARCHAR(50)    NULL,
    Liberado_Pagto_80       NVARCHAR(50)    NULL,
    lpp80sent               NVARCHAR(50)    NULL,
    lpp80DocNumber          NVARCHAR(50)    NULL,
    pmoApproval80           NVARCHAR(50)    NULL,
    Liberado_Pagto_20       NVARCHAR(50)    NULL,
    lpp20sent               NVARCHAR(50)    NULL,
    lpp20DocNumber          NVARCHAR(50)    NULL,
    pmoApproval20           NVARCHAR(50)    NULL,
    sapMigo                 NVARCHAR(50)    NULL,
    UF                      NVARCHAR(50)    NULL,
    Regional                NVARCHAR(20)    NULL,
);

-- ============================================================
-- 3.2 BULK INSERT — staging.ID_NUM_SERVICES
-- ============================================================
-- Fonte: ID Num Services.xlsx exportado como CSV UTF-8
-- ============================================================
TRUNCATE TABLE staging.ID_NUM_SERVICES;
BULK INSERT staging.ID_NUM_SERVICES
FROM 'C:\Users\salmeida\Documents\00. Dep_PMO\00. PMO_SIAEBR\01. DB_SIAEBR\ID Num Services.csv'
WITH (
   -- DATA_SOURCE         = N'',           -- remover se não usar external data source
   -- FORMAT              = 'CSV',
    FIRSTROW            = 2,             -- pula cabeçalho
    FIELDTERMINATOR     = ';',
    ROWTERMINATOR       = '\n',
    CODEPAGE            = '65001',       -- UTF-8
    TABLOCK
    );

-- ============================================================
-- 3.4 EXECUTAR PROCEDURE dbo.sp_carga_ID_NUM_SERVICES
-- ============================================================

TRUNCATE TABLE dbo.ID_NUM_SERVICES;

-- Executar carga com valores padrão
EXEC dbo.sp_carga_ID_NUM_SERVICES;

-- Sem truncar staging e com limite de 50 erros
EXEC dbo.sp_carga_ID_NUM_SERVICES 
    @p_truncate_staging = 0,
    @p_max_errors = 50;

-- ========================================================================
-- 3.3 Created by GitHub Copilot in SSMS - STORE PROCEDURE dbo.sp_carga_ID_NUM_SERVICES
-- Procedure para validar, transformar e carregar dados de staging.ID_NUM_SERVICES para dbo.ID_NUM_SERVICES
-- Inclui conversão de tipos, validação de dados e logging de ETL
-- ========================================================================

CREATE OR ALTER PROCEDURE dbo.sp_carga_ID_NUM_SERVICES
    @p_truncate_staging BIT = 1,  -- 1 = limpa staging após sucesso
    @p_max_errors INT = 100       -- máximo de erros permitidos
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @v_inicio DATETIME2 = GETDATE();
    DECLARE @v_registros_lidos INT = 0;
    DECLARE @v_registros_ok INT = 0;
    DECLARE @v_registros_erro INT = 0;
    DECLARE @v_status NVARCHAR(20) = 'RUNNING';
    DECLARE @v_mensagem NVARCHAR(1000);
    DECLARE @v_id_log INT;
    
    BEGIN TRY
        -- 1. Registrar início da carga
        INSERT INTO dbo.ETL_CARGA_LOG (tabela, fonte, dt_inicio, status)
        VALUES ('ID_NUM_SERVICES', 'staging.ID_NUM_SERVICES', @v_inicio, @v_status);
        
        SET @v_id_log = SCOPE_IDENTITY();
        
        -- 2. Contar registros no staging
        SELECT @v_registros_lidos = COUNT(*) FROM staging.ID_NUM_SERVICES;
        
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ID_NUM_SERVICES — INICIADO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Registros no staging: ' + CAST(@v_registros_lidos AS VARCHAR);
        
        -- 3. Validação básica
        IF @v_registros_lidos = 0
        BEGIN
            SET @v_mensagem = 'Nenhum registro encontrado em staging.ID_NUM_SERVICES';
            RAISERROR(@v_mensagem, 16, 1);
        END;
        
        -- 4. Inserir dados com conversão de tipos
        INSERT INTO dbo.ID_NUM_SERVICES (
            ID, Projeto, ID_ITEM, Cod_For_SAP, Fornecedor, LINK_SIAE_ID, WBS_SAP,
            CodePro, Description, Qty, Value_Serv, Req_PO_D, PO_Number, Issue_Date,
            Note, Owner, Status, OK, Data_Aprovacao, Liberado_Pagto_80, lpp80sent,
            lpp80DocNumber, pmoApproval80, Liberado_Pagto_20, lpp20sent, lpp20DocNumber,
            pmoApproval20, sapMigo, UF, Regional
        )
        SELECT
            ID,
            Projeto,
            ID_ITEM,
            Cod_For_SAP,
            Fornecedor,
            LINK_SIAE_ID,
            WBS_SAP,
            CodePro,
            Description,
            TRY_CAST(Qty AS DECIMAL(18,3)),
            TRY_CAST(Value_Serv AS DECIMAL(18,2)),
            TRY_CAST(Req_PO_D AS DATE),
            PO_Number,
            TRY_CAST(Issue_Date AS DATE),
            Note,
            Owner,
            Status,
            CASE WHEN OK IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            TRY_CAST(Data_Aprovacao AS DATE),
            TRY_CAST(Liberado_Pagto_80 AS DATE),
            CASE WHEN lpp80sent IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            lpp80DocNumber,
            CASE WHEN pmoApproval80 IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            TRY_CAST(Liberado_Pagto_20 AS DATE),
            CASE WHEN lpp20sent IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            lpp20DocNumber,
            CASE WHEN pmoApproval20 IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            CASE WHEN sapMigo IN ('1', 'sim', 'yes', 'true') THEN 1 ELSE 0 END,
            UF,
            Regional
        FROM staging.ID_NUM_SERVICES
        WHERE Projeto IS NOT NULL;
        
        SET @v_registros_ok = @@ROWCOUNT;
        SET @v_registros_erro = @v_registros_lidos - @v_registros_ok;
        
        -- 5. Validação de erros
        IF @v_registros_erro > @p_max_errors
        BEGIN
            SET @v_mensagem = 'Erros de validação excedem o limite: ' + CAST(@v_registros_erro AS VARCHAR);
            RAISERROR(@v_mensagem, 16, 1);
        END;
        
        -- 6. Limpar staging se solicitado
        IF @p_truncate_staging = 1
        BEGIN
            TRUNCATE TABLE staging.ID_NUM_SERVICES;
            PRINT 'Tabela staging.ID_NUM_SERVICES truncada.';
        END;
        
        -- 7. Atualizar log com sucesso
        SET @v_status = 'OK';
        UPDATE dbo.ETL_CARGA_LOG
        SET dt_fim = GETDATE(),
            registros_lidos = @v_registros_lidos,
            registros_ok = @v_registros_ok,
            status = @v_status,
            mensagem = 'Carga concluída com sucesso'
        WHERE id = @v_id_log;
        
        -- 8. Relatório final
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ID_NUM_SERVICES — SUCESSO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Total registros lidos: ' + CAST(@v_registros_lidos AS VARCHAR);
        PRINT 'Registros inseridos: ' + CAST(@v_registros_ok AS VARCHAR);
        PRINT 'Registros com erro: ' + CAST(@v_registros_erro AS VARCHAR);
        PRINT 'Tempo de execução: ' + CAST(DATEDIFF(SECOND, @v_inicio, GETDATE()) AS VARCHAR) + ' segundos';
        PRINT '═══════════════════════════════════════════════════════';
        
    END TRY
    BEGIN CATCH
        SET @v_status = 'ERROR';
        SET @v_mensagem = ERROR_MESSAGE();
        
        -- Atualizar log com erro
        UPDATE dbo.ETL_CARGA_LOG
        SET dt_fim = GETDATE(),
            registros_lidos = @v_registros_lidos,
            registros_ok = @v_registros_ok,
            status = @v_status,
            mensagem = @v_mensagem
        WHERE id = @v_id_log;
        
        -- Relatório de erro
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'CARGA ID_NUM_SERVICES — ERRO';
        PRINT '═══════════════════════════════════════════════════════';
        PRINT 'Mensagem: ' + @v_mensagem;
        PRINT 'Registros processados: ' + CAST(@v_registros_ok AS VARCHAR) + '/' + CAST(@v_registros_lidos AS VARCHAR);
        PRINT '═══════════════════════════════════════════════════════';
        
        RAISERROR(@v_mensagem, 16, 1);
    END CATCH;
END;
GO

-- ============================================================
-- 4. MAT_RAZAO  (origem: SAP RAZAO CMV - custos HW)
-- ============================================================
CREATE TABLE dbo.MAT_RAZAO (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    Referencia              NVARCHAR(50)    NULL,
    Ano_Mes                 DATE            NULL,
    Num_Documento           NVARCHAR(20)    NULL,
    Texto                   NVARCHAR(500)   NULL,
    Montante                DECIMAL(18,2)   NULL,
    Data_Documento          DATE            NULL,
    Elemento_PEP            NVARCHAR(50)    NULL,
    Documento_Compras       NVARCHAR(50)    NULL,
    Material                NVARCHAR(50)    NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE()
);
GO

CREATE INDEX IX_MRAZ_ELEMENTO_PEP     ON dbo.MAT_RAZAO (Elemento_PEP);
CREATE INDEX IX_MRAZ_ANO_MES          ON dbo.MAT_RAZAO (Ano_Mes);
CREATE INDEX IX_MRAZ_MATERIAL         ON dbo.MAT_RAZAO (Material);
GO

-- ============================================================
-- 5. TRANSP  (origem: Planilha Excel Transporte)
-- ============================================================
CREATE TABLE dbo.TRANSP (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    Project_Name            NVARCHAR(100)   NULL,
    City_Delivery           NVARCHAR(100)   NULL,
    UF                      CHAR(2)         NULL,
    PM                      NVARCHAR(100)   NULL,
    WBS_SAP                 NVARCHAR(50)    NULL,
    SIAE_ID                 NVARCHAR(50)    NULL,
    Shipping_Date           DATE            NULL,
    Total_Amount            DECIMAL(18,2)   NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TRANSP_SIAE_ID        ON dbo.TRANSP (SIAE_ID);
CREATE INDEX IX_TRANSP_WBS_SAP        ON dbo.TRANSP (WBS_SAP);
GO

-- ============================================================
-- 6. FIELD_COST  (origem: Planilha Excel Field Cost)
-- ============================================================
CREATE TABLE dbo.FIELD_COST (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    SIAE_ID                 NVARCHAR(50)    NULL,
    WBS                     NVARCHAR(50)    NULL,
    Funcionario             NVARCHAR(200)   NULL,
    Semana                  NVARCHAR(10)    NULL,
    Total_Geral             DECIMAL(18,2)   NULL,
    Obs                     NVARCHAR(500)   NULL,
    dt_carga                DATETIME2       DEFAULT GETDATE()
);
GO

CREATE INDEX IX_FC_SIAE_ID            ON dbo.FIELD_COST (SIAE_ID);
CREATE INDEX IX_FC_WBS                ON dbo.FIELD_COST (WBS);
GO

-- ============================================================
-- 7. Tabela de controle de carga ETL
-- ============================================================
CREATE TABLE dbo.ETL_CARGA_LOG (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    tabela          NVARCHAR(50)    NOT NULL,
    fonte           NVARCHAR(200)   NOT NULL,
    dt_inicio       DATETIME2       NOT NULL,
    dt_fim          DATETIME2       NULL,
    registros_lidos INT             NULL,
    registros_ok    INT             NULL,
    status          NVARCHAR(20)    NULL,   -- RUNNING / OK / ERROR
    mensagem        NVARCHAR(1000)  NULL
);
GO
