/* Complemento do banco para o site MVC. Rode depois do 01_banco.sql. */
USE PousadaMareMansa;
GO
CREATE PROCEDURE sp_ListarTiposQuarto AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.IdTipoQuarto, t.Nome, t.Capacidade, t.PrecoDiaria, t.Acessivel, t.Descricao,
           (SELECT STRING_AGG(c.Nome, ', ') FROM TipoQuartoComodidade x
            JOIN Comodidade c ON c.IdComodidade = x.IdComodidade
            WHERE x.IdTipoQuarto = t.IdTipoQuarto) AS Comodidades
    FROM TipoQuarto t ORDER BY t.PrecoDiaria;
END;
GO
CREATE PROCEDURE sp_ConsultarReserva @Codigo VARCHAR(10), @Email NVARCHAR(160) AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.Codigo, v.Tipo, v.DataEntrada, v.DataSaida, v.Noites, v.QtdHospedes, v.ValorTotal, v.ValorPago, v.Status
    FROM vw_ReservasDetalhadas v
    JOIN Reserva r ON r.IdReserva = v.IdReserva
    JOIN Hospede h ON h.IdHospede = r.IdHospede
    WHERE v.Codigo = @Codigo AND h.Email = @Email;
END;
GO
-- O hóspede só cancela informando código e e-mail da própria reserva.
CREATE PROCEDURE sp_CancelarReservaHospede @Codigo VARCHAR(10), @Email NVARCHAR(160), @Gratuito BIT OUTPUT AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Reserva r JOIN Hospede h ON h.IdHospede = r.IdHospede
                   WHERE r.Codigo = @Codigo AND h.Email = @Email)
        THROW 50006, 'Reserva não encontrada para este código e e-mail.', 1;
    EXEC sp_CancelarReserva @Codigo, @Gratuito OUTPUT;
END;
GO
CREATE PROCEDURE sp_RegistrarMensagem @Nome NVARCHAR(120), @Email NVARCHAR(160), @Texto NVARCHAR(1000) AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO MensagemContato (Nome, Email, Texto) VALUES (@Nome, @Email, @Texto);
END;
GO
CREATE PROCEDURE sp_ObterAdmin @Login VARCHAR(40) AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdUsuario, Login, SenhaHash, Salt, Perfil FROM UsuarioAdmin WHERE Login = @Login AND Ativo = 1;
END;
GO
CREATE PROCEDURE sp_CriarAdmin @Login VARCHAR(40), @Hash VARBINARY(64), @Salt VARBINARY(32), @Perfil VARCHAR(15) AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO UsuarioAdmin (Login, SenhaHash, Salt, Perfil) VALUES (@Login, @Hash, @Salt, @Perfil);
END;
GO
/* Permissões: o site anônimo só executa o que precisa. */
REVOKE EXECUTE ON sp_CancelarReserva FROM rl_site;
GRANT EXECUTE ON sp_ListarTiposQuarto TO rl_site;
GRANT EXECUTE ON sp_ConsultarReserva TO rl_site;
GRANT EXECUTE ON sp_CancelarReservaHospede TO rl_site;
GRANT EXECUTE ON sp_RegistrarMensagem TO rl_site;
GRANT EXECUTE ON sp_ObterAdmin TO rl_site;
GRANT EXECUTE ON sp_CancelarReserva TO rl_gerente;
GRANT EXECUTE ON sp_CriarAdmin TO rl_gerente;
GO
/* Usuários de banco usados pela aplicação (troque as senhas):
CREATE LOGIN app_site  WITH PASSWORD = '<senha-forte>';  CREATE USER app_site  FOR LOGIN app_site;  ALTER ROLE rl_site    ADD MEMBER app_site;
CREATE LOGIN app_admin WITH PASSWORD = '<senha-forte>';  CREATE USER app_admin FOR LOGIN app_admin; ALTER ROLE rl_gerente ADD MEMBER app_admin;
*/
