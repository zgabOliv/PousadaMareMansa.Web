/* ============================================================
   PIM IV - Etapa 7: Projeto do Banco de Dados
   Sistema: Pousada Maré Mansa (empresa fictícia)
   SGBD: Microsoft SQL Server 2019+ (T-SQL)
   Conteúdo: tabelas, relacionamentos, índices, procedures,
             triggers, views, segurança e dados de exemplo.
   ============================================================ */

IF DB_ID('PousadaMareMansa') IS NULL CREATE DATABASE PousadaMareMansa;
GO
USE PousadaMareMansa;
GO

/* ------------------------------------------------------------
   1. TABELAS
   ------------------------------------------------------------ */

CREATE TABLE Hospede (
    IdHospede    INT IDENTITY(1,1) CONSTRAINT PK_Hospede PRIMARY KEY,
    Nome         NVARCHAR(120) NOT NULL,
    Email        NVARCHAR(160) MASKED WITH (FUNCTION = 'email()') NOT NULL,
    Telefone     VARCHAR(20)   MASKED WITH (FUNCTION = 'partial(0,"(**) *****-",4)') NOT NULL,
    Documento    VARCHAR(14)   MASKED WITH (FUNCTION = 'partial(0,"***.***.",2)') NULL,
    DataCadastro DATETIME2(0)  NOT NULL CONSTRAINT DF_Hospede_Data DEFAULT SYSDATETIME(),
    Ativo        BIT           NOT NULL CONSTRAINT DF_Hospede_Ativo DEFAULT 1,
    CONSTRAINT UQ_Hospede_Email UNIQUE (Email)
);

CREATE TABLE TipoQuarto (
    IdTipoQuarto INT IDENTITY(1,1) CONSTRAINT PK_TipoQuarto PRIMARY KEY,
    Nome         NVARCHAR(60)  NOT NULL CONSTRAINT UQ_TipoQuarto_Nome UNIQUE,
    Capacidade   TINYINT       NOT NULL CONSTRAINT CK_Tipo_Cap CHECK (Capacidade BETWEEN 1 AND 8),
    PrecoDiaria  DECIMAL(10,2) NOT NULL CONSTRAINT CK_Tipo_Preco CHECK (PrecoDiaria > 0),
    Acessivel    BIT           NOT NULL CONSTRAINT DF_Tipo_Acess DEFAULT 0,
    Descricao    NVARCHAR(300) NULL
);

CREATE TABLE Quarto (
    IdQuarto     INT IDENTITY(1,1) CONSTRAINT PK_Quarto PRIMARY KEY,
    Numero       VARCHAR(10) NOT NULL CONSTRAINT UQ_Quarto_Numero UNIQUE,
    IdTipoQuarto INT NOT NULL CONSTRAINT FK_Quarto_Tipo REFERENCES TipoQuarto(IdTipoQuarto),
    Ativo        BIT NOT NULL CONSTRAINT DF_Quarto_Ativo DEFAULT 1
);

CREATE TABLE Comodidade (
    IdComodidade INT IDENTITY(1,1) CONSTRAINT PK_Comodidade PRIMARY KEY,
    Nome         NVARCHAR(80) NOT NULL CONSTRAINT UQ_Comodidade_Nome UNIQUE
);

-- Relacionamento N:N entre tipo de quarto e comodidade
CREATE TABLE TipoQuartoComodidade (
    IdTipoQuarto INT NOT NULL CONSTRAINT FK_TQC_Tipo REFERENCES TipoQuarto(IdTipoQuarto),
    IdComodidade INT NOT NULL CONSTRAINT FK_TQC_Com  REFERENCES Comodidade(IdComodidade),
    CONSTRAINT PK_TQC PRIMARY KEY (IdTipoQuarto, IdComodidade)
);

CREATE TABLE Reserva (
    IdReserva     INT IDENTITY(1,1) CONSTRAINT PK_Reserva PRIMARY KEY,
    Codigo        VARCHAR(10)   NOT NULL CONSTRAINT UQ_Reserva_Codigo UNIQUE,
    IdHospede     INT           NOT NULL CONSTRAINT FK_Reserva_Hospede REFERENCES Hospede(IdHospede),
    IdQuarto      INT           NOT NULL CONSTRAINT FK_Reserva_Quarto  REFERENCES Quarto(IdQuarto),
    DataEntrada   DATE          NOT NULL,
    DataSaida     DATE          NOT NULL,
    QtdHospedes   TINYINT       NOT NULL CONSTRAINT CK_Reserva_Qtd CHECK (QtdHospedes >= 1),
    ValorTotal    DECIMAL(10,2) NOT NULL CONSTRAINT CK_Reserva_Valor CHECK (ValorTotal >= 0),
    Status        VARCHAR(12)   NOT NULL CONSTRAINT DF_Reserva_Status DEFAULT 'Pendente',
    DataCriacao   DATETIME2(0)  NOT NULL CONSTRAINT DF_Reserva_Criacao DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Reserva_Datas  CHECK (DataSaida > DataEntrada),
    CONSTRAINT CK_Reserva_Status CHECK (Status IN ('Pendente','Confirmada','Cancelada','Concluida'))
);

CREATE TABLE Pagamento (
    IdPagamento   INT IDENTITY(1,1) CONSTRAINT PK_Pagamento PRIMARY KEY,
    IdReserva     INT           NOT NULL CONSTRAINT FK_Pag_Reserva REFERENCES Reserva(IdReserva),
    Valor         DECIMAL(10,2) NOT NULL CONSTRAINT CK_Pag_Valor CHECK (Valor > 0),
    Forma         VARCHAR(10)   NOT NULL CONSTRAINT CK_Pag_Forma  CHECK (Forma IN ('Pix','Cartao','Dinheiro')),
    Status        VARCHAR(10)   NOT NULL CONSTRAINT DF_Pag_Status DEFAULT 'Aprovado'
                  CONSTRAINT CK_Pag_Status CHECK (Status IN ('Pendente','Aprovado','Recusado','Estornado')),
    DataPagamento DATETIME2(0)  NOT NULL CONSTRAINT DF_Pag_Data DEFAULT SYSDATETIME()
);

CREATE TABLE Avaliacao (
    IdAvaliacao INT IDENTITY(1,1) CONSTRAINT PK_Avaliacao PRIMARY KEY,
    IdReserva   INT NOT NULL CONSTRAINT UQ_Aval_Reserva UNIQUE   -- 1 avaliação por reserva
                CONSTRAINT FK_Aval_Reserva REFERENCES Reserva(IdReserva),
    Nota        TINYINT NOT NULL CONSTRAINT CK_Aval_Nota CHECK (Nota BETWEEN 1 AND 5),
    Comentario  NVARCHAR(500) NULL,
    DataAval    DATETIME2(0) NOT NULL CONSTRAINT DF_Aval_Data DEFAULT SYSDATETIME()
);

CREATE TABLE MensagemContato (
    IdMensagem INT IDENTITY(1,1) CONSTRAINT PK_Mensagem PRIMARY KEY,
    Nome       NVARCHAR(120) NOT NULL,
    Email      NVARCHAR(160) NOT NULL,
    Texto      NVARCHAR(1000) NOT NULL,
    DataEnvio  DATETIME2(0) NOT NULL CONSTRAINT DF_Msg_Data DEFAULT SYSDATETIME(),
    Respondida BIT NOT NULL CONSTRAINT DF_Msg_Resp DEFAULT 0
);

CREATE TABLE UsuarioAdmin (
    IdUsuario  INT IDENTITY(1,1) CONSTRAINT PK_UsuarioAdmin PRIMARY KEY,
    Login      VARCHAR(40)    NOT NULL CONSTRAINT UQ_Admin_Login UNIQUE,
    SenhaHash  VARBINARY(64)  NOT NULL,   -- hash gerado pela aplicação .NET (PBKDF2/bcrypt)
    Salt       VARBINARY(32)  NOT NULL,
    Perfil     VARCHAR(15)    NOT NULL CONSTRAINT CK_Admin_Perfil CHECK (Perfil IN ('Gerente','Recepcao')),
    Ativo      BIT            NOT NULL CONSTRAINT DF_Admin_Ativo DEFAULT 1
);

CREATE TABLE LogReserva (
    IdLog          INT IDENTITY(1,1) CONSTRAINT PK_LogReserva PRIMARY KEY,
    IdReserva      INT NOT NULL,
    StatusAnterior VARCHAR(12) NULL,
    StatusNovo     VARCHAR(12) NOT NULL,
    Usuario        SYSNAME NOT NULL CONSTRAINT DF_Log_User DEFAULT SUSER_SNAME(),
    DataLog        DATETIME2(0) NOT NULL CONSTRAINT DF_Log_Data DEFAULT SYSDATETIME()
);
GO

/* ------------------------------------------------------------
   2. ÍNDICES (otimização)
   ------------------------------------------------------------ */

-- Verificação de disponibilidade: filtra por quarto e intervalo de datas
CREATE NONCLUSTERED INDEX IX_Reserva_Quarto_Datas
    ON Reserva (IdQuarto, DataEntrada, DataSaida) INCLUDE (Status);

-- Histórico de reservas de um hóspede
CREATE NONCLUSTERED INDEX IX_Reserva_Hospede ON Reserva (IdHospede) INCLUDE (Status, DataEntrada);

-- Painel administrativo: reservas por status e data de entrada
CREATE NONCLUSTERED INDEX IX_Reserva_Status_Entrada ON Reserva (Status, DataEntrada);

-- Soma de pagamentos por reserva
CREATE NONCLUSTERED INDEX IX_Pagamento_Reserva ON Pagamento (IdReserva) INCLUDE (Valor, Status);

-- Quartos por tipo
CREATE NONCLUSTERED INDEX IX_Quarto_Tipo ON Quarto (IdTipoQuarto) WHERE Ativo = 1;
GO

/* ------------------------------------------------------------
   3. VIEWS
   ------------------------------------------------------------ */

CREATE VIEW vw_ReservasDetalhadas AS
SELECT r.IdReserva, r.Codigo, h.Nome AS Hospede, q.Numero AS Quarto, t.Nome AS Tipo,
       r.DataEntrada, r.DataSaida, DATEDIFF(DAY, r.DataEntrada, r.DataSaida) AS Noites,
       r.QtdHospedes, r.ValorTotal, r.Status,
       ISNULL((SELECT SUM(p.Valor) FROM Pagamento p
               WHERE p.IdReserva = r.IdReserva AND p.Status = 'Aprovado'), 0) AS ValorPago
FROM Reserva r
JOIN Hospede h   ON h.IdHospede = r.IdHospede
JOIN Quarto q    ON q.IdQuarto = r.IdQuarto
JOIN TipoQuarto t ON t.IdTipoQuarto = q.IdTipoQuarto;
GO

CREATE VIEW vw_ReceitaMensal AS
SELECT YEAR(p.DataPagamento) AS Ano, MONTH(p.DataPagamento) AS Mes,
       SUM(p.Valor) AS Receita, COUNT(DISTINCT p.IdReserva) AS Reservas
FROM Pagamento p
WHERE p.Status = 'Aprovado'
GROUP BY YEAR(p.DataPagamento), MONTH(p.DataPagamento);
GO

/* ------------------------------------------------------------
   4. STORED PROCEDURES
   ------------------------------------------------------------ */

-- 4.1 Busca de tipos de quarto disponíveis para o período
CREATE PROCEDURE sp_BuscarDisponibilidade
    @Entrada DATE, @Saida DATE, @Hospedes TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Saida <= @Entrada OR @Entrada < CAST(SYSDATETIME() AS DATE)
        THROW 50001, 'Período inválido: a saída deve ser posterior à entrada e a entrada não pode ser passada.', 1;

    DECLARE @Noites INT = DATEDIFF(DAY, @Entrada, @Saida);

    SELECT t.IdTipoQuarto, t.Nome, t.Capacidade, t.PrecoDiaria,
           t.PrecoDiaria * @Noites AS ValorTotal,
           COUNT(q.IdQuarto) AS QuartosLivres
    FROM TipoQuarto t
    JOIN Quarto q ON q.IdTipoQuarto = t.IdTipoQuarto AND q.Ativo = 1
    WHERE t.Capacidade >= @Hospedes
      AND NOT EXISTS (SELECT 1 FROM Reserva r
                      WHERE r.IdQuarto = q.IdQuarto
                        AND r.Status <> 'Cancelada'
                        AND r.DataEntrada < @Saida AND r.DataSaida > @Entrada)
    GROUP BY t.IdTipoQuarto, t.Nome, t.Capacidade, t.PrecoDiaria;
END;
GO

-- 4.2 Criação de reserva (transação com bloqueio contra reserva dupla)
CREATE PROCEDURE sp_CriarReserva
    @Nome NVARCHAR(120), @Email NVARCHAR(160), @Telefone VARCHAR(20),
    @IdTipoQuarto INT, @Entrada DATE, @Saida DATE, @Hospedes TINYINT,
    @Codigo VARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Saida <= @Entrada OR @Entrada < CAST(SYSDATETIME() AS DATE)
        THROW 50001, 'Período inválido.', 1;
    IF LEN(LTRIM(RTRIM(@Nome))) < 3
        THROW 50002, 'Nome inválido.', 1;

    BEGIN TRAN;
        DECLARE @IdHospede INT, @IdQuarto INT, @Preco DECIMAL(10,2), @Cap TINYINT;

        SELECT @Preco = PrecoDiaria, @Cap = Capacidade FROM TipoQuarto WHERE IdTipoQuarto = @IdTipoQuarto;
        IF @Preco IS NULL THROW 50003, 'Tipo de quarto inexistente.', 1;
        IF @Hospedes > @Cap THROW 50004, 'Quantidade de hóspedes acima da capacidade do quarto.', 1;

        -- Reaproveita o cadastro do hóspede pelo e-mail
        SELECT @IdHospede = IdHospede FROM Hospede WHERE Email = @Email;
        IF @IdHospede IS NULL
        BEGIN
            INSERT INTO Hospede (Nome, Email, Telefone) VALUES (@Nome, @Email, @Telefone);
            SET @IdHospede = SCOPE_IDENTITY();
        END
        ELSE UPDATE Hospede SET Telefone = @Telefone WHERE IdHospede = @IdHospede;

        -- Primeiro quarto livre do tipo (bloqueio evita duas reservas simultâneas)
        SELECT TOP (1) @IdQuarto = q.IdQuarto
        FROM Quarto q
        WHERE q.IdTipoQuarto = @IdTipoQuarto AND q.Ativo = 1
          AND NOT EXISTS (SELECT 1 FROM Reserva r WITH (UPDLOCK, HOLDLOCK)
                          WHERE r.IdQuarto = q.IdQuarto AND r.Status <> 'Cancelada'
                            AND r.DataEntrada < @Saida AND r.DataSaida > @Entrada)
        ORDER BY q.Numero;

        IF @IdQuarto IS NULL THROW 50005, 'Não há quarto disponível deste tipo no período.', 1;

        SET @Codigo = 'MM-' + UPPER(LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 5));

        INSERT INTO Reserva (Codigo, IdHospede, IdQuarto, DataEntrada, DataSaida, QtdHospedes, ValorTotal)
        VALUES (@Codigo, @IdHospede, @IdQuarto, @Entrada, @Saida, @Hospedes,
                @Preco * DATEDIFF(DAY, @Entrada, @Saida));
    COMMIT;
END;
GO

-- 4.3 Cancelamento (regra: gratuito até 7 dias antes da entrada)
CREATE PROCEDURE sp_CancelarReserva
    @Codigo VARCHAR(10), @Gratuito BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @Entrada DATE, @Status VARCHAR(12);

    SELECT @Id = IdReserva, @Entrada = DataEntrada, @Status = Status FROM Reserva WHERE Codigo = @Codigo;
    IF @Id IS NULL THROW 50006, 'Reserva não encontrada.', 1;
    IF @Status IN ('Cancelada','Concluida') THROW 50007, 'Esta reserva não pode mais ser cancelada.', 1;

    SET @Gratuito = CASE WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), @Entrada) >= 7 THEN 1 ELSE 0 END;
    UPDATE Reserva SET Status = 'Cancelada' WHERE IdReserva = @Id;
END;
GO

-- 4.4 Registro de pagamento
CREATE PROCEDURE sp_RegistrarPagamento
    @Codigo VARCHAR(10), @Valor DECIMAL(10,2), @Forma VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @Status VARCHAR(12);
    SELECT @Id = IdReserva, @Status = Status FROM Reserva WHERE Codigo = @Codigo;
    IF @Id IS NULL THROW 50006, 'Reserva não encontrada.', 1;
    IF @Status = 'Cancelada' THROW 50008, 'Não é possível pagar uma reserva cancelada.', 1;
    INSERT INTO Pagamento (IdReserva, Valor, Forma) VALUES (@Id, @Valor, @Forma);
END;
GO

-- 4.5 Relatório de ocupação por período (uso administrativo)
CREATE PROCEDURE sp_RelatorioOcupacao
    @Inicio DATE, @Fim DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.Nome AS Tipo,
           COUNT(r.IdReserva) AS Reservas,
           SUM(DATEDIFF(DAY,
               CASE WHEN r.DataEntrada < @Inicio THEN @Inicio ELSE r.DataEntrada END,
               CASE WHEN r.DataSaida   > @Fim    THEN @Fim    ELSE r.DataSaida   END)) AS DiariasOcupadas
    FROM TipoQuarto t
    JOIN Quarto q ON q.IdTipoQuarto = t.IdTipoQuarto
    LEFT JOIN Reserva r ON r.IdQuarto = q.IdQuarto AND r.Status <> 'Cancelada'
         AND r.DataEntrada < @Fim AND r.DataSaida > @Inicio
    GROUP BY t.Nome;
END;
GO

/* ------------------------------------------------------------
   5. TRIGGERS
   ------------------------------------------------------------ */

-- 5.1 Barreira final contra reservas sobrepostas no mesmo quarto
CREATE TRIGGER trg_Reserva_SemConflito ON Reserva AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN Reserva r ON r.IdQuarto = i.IdQuarto AND r.IdReserva <> i.IdReserva
               WHERE i.Status <> 'Cancelada' AND r.Status <> 'Cancelada'
                 AND r.DataEntrada < i.DataSaida AND r.DataSaida > i.DataEntrada)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50010, 'Conflito: o quarto já está reservado neste período.', 1;
    END
END;
GO

-- 5.2 Auditoria das mudanças de status da reserva
CREATE TRIGGER trg_Reserva_Auditoria ON Reserva AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LogReserva (IdReserva, StatusAnterior, StatusNovo)
    SELECT i.IdReserva, d.Status, i.Status
    FROM inserted i
    LEFT JOIN deleted d ON d.IdReserva = i.IdReserva
    WHERE d.IdReserva IS NULL OR d.Status <> i.Status;
END;
GO

-- 5.3 Confirma a reserva quando o total pago cobre o valor
CREATE TRIGGER trg_Pagamento_Confirma ON Pagamento AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE r SET Status = 'Confirmada'
    FROM Reserva r
    WHERE r.Status = 'Pendente'
      AND r.IdReserva IN (SELECT IdReserva FROM inserted)
      AND (SELECT SUM(p.Valor) FROM Pagamento p
           WHERE p.IdReserva = r.IdReserva AND p.Status = 'Aprovado') >= r.ValorTotal;
END;
GO

-- 5.4 Avaliação só é permitida para reservas concluídas ou já iniciadas
CREATE TRIGGER trg_Avaliacao_Valida ON Avaliacao AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN Reserva r ON r.IdReserva = i.IdReserva
               WHERE r.Status NOT IN ('Confirmada','Concluida') OR r.DataEntrada > CAST(SYSDATETIME() AS DATE))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50011, 'Só é possível avaliar uma estadia confirmada que já começou.', 1;
    END
END;
GO

/* ------------------------------------------------------------
   6. SEGURANÇA
   ------------------------------------------------------------ */

-- Papéis: a aplicação do site só executa procedures; nunca acessa tabelas diretamente.
CREATE ROLE rl_site;
CREATE ROLE rl_recepcao;
CREATE ROLE rl_gerente;

GRANT EXECUTE ON sp_BuscarDisponibilidade TO rl_site, rl_recepcao, rl_gerente;
GRANT EXECUTE ON sp_CriarReserva          TO rl_site, rl_recepcao, rl_gerente;
GRANT EXECUTE ON sp_CancelarReserva       TO rl_site, rl_recepcao, rl_gerente;
GRANT EXECUTE ON sp_RegistrarPagamento    TO rl_recepcao, rl_gerente;
GRANT EXECUTE ON sp_RelatorioOcupacao     TO rl_gerente;

GRANT SELECT ON vw_ReservasDetalhadas TO rl_recepcao, rl_gerente;
GRANT SELECT ON vw_ReceitaMensal      TO rl_gerente;
GRANT SELECT ON TipoQuarto            TO rl_site;   -- catálogo público de quartos

DENY SELECT, INSERT, UPDATE, DELETE ON Hospede      TO rl_site;
DENY SELECT, INSERT, UPDATE, DELETE ON Reserva      TO rl_site;
DENY SELECT, INSERT, UPDATE, DELETE ON UsuarioAdmin TO rl_site, rl_recepcao;
DENY SELECT ON LogReserva TO rl_site, rl_recepcao;
-- Recepção vê dados mascarados (e-mail, telefone, documento); o gerente pode ver tudo:
GRANT UNMASK TO rl_gerente;

/* Exemplo de criação de usuários (ajuste as senhas antes de usar):
   CREATE LOGIN app_site WITH PASSWORD = '<senha-forte>';
   CREATE USER  app_site FOR LOGIN app_site;
   ALTER ROLE rl_site ADD MEMBER app_site;
*/
GO

/* ------------------------------------------------------------
   7. DADOS DE EXEMPLO
   ------------------------------------------------------------ */

INSERT INTO TipoQuarto (Nome, Capacidade, PrecoDiaria, Acessivel, Descricao) VALUES
(N'Quarto Brisa',      2, 260.00, 0, N'Cama de casal e varanda com rede'),
(N'Quarto Coral',      3, 340.00, 0, N'Casal e solteiro, vista para o jardim'),
(N'Suíte Família',     4, 450.00, 0, N'Duas camas de casal e mesa de refeições'),
(N'Térreo Acessível',  2, 280.00, 1, N'Rampa, porta ampla e banheiro com barras de apoio');

INSERT INTO Quarto (Numero, IdTipoQuarto) VALUES
('101',1),('102',1),('201',2),('202',2),('203',3),('001',4);

INSERT INTO Comodidade (Nome) VALUES
(N'Ar-condicionado'),(N'Wi-Fi'),(N'Frigobar'),(N'Varanda'),(N'Rampa de acesso'),(N'Banheiro adaptado');

INSERT INTO TipoQuartoComodidade VALUES
(1,1),(1,2),(1,4),(2,1),(2,2),(2,3),(3,1),(3,2),(4,2),(4,5),(4,6);

/* ------------------------------------------------------------
   8. EXEMPLOS DE USO (rode após criar tudo)
   ------------------------------------------------------------
   DECLARE @cod VARCHAR(10);
   EXEC sp_BuscarDisponibilidade '2026-12-20', '2026-12-23', 2;
   EXEC sp_CriarReserva N'Camila Ribeiro', N'camila@email.com', '13988887777',
        1, '2026-12-20', '2026-12-23', 2, @cod OUTPUT;
   SELECT @cod AS Codigo;
   EXEC sp_RegistrarPagamento @cod, 780.00, 'Pix';   -- trigger confirma a reserva
   SELECT * FROM vw_ReservasDetalhadas;
   SELECT * FROM LogReserva;
   ------------------------------------------------------------ */
