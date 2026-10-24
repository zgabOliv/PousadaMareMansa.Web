using System.Data;
using Microsoft.Data.SqlClient;
using PousadaMareMansa.Web.Models;
namespace PousadaMareMansa.Web.Data;

/// <summary>Acesso a dados do site público. Só chama stored procedures.</summary>
public class PousadaRepository
{
    private readonly Db _db;
    public PousadaRepository(Db db) => _db = db;

    public async Task<List<TipoQuarto>> ListarTiposAsync()
    {
        var lista = new List<TipoQuarto>();
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_ListarTiposQuarto");
        await using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
            lista.Add(new TipoQuarto
            {
                IdTipoQuarto = r.GetInt32(r.GetOrdinal("IdTipoQuarto")),
                Nome = r.GetString(r.GetOrdinal("Nome")),
                Capacidade = r.GetByte(r.GetOrdinal("Capacidade")),
                PrecoDiaria = r.GetDecimal(r.GetOrdinal("PrecoDiaria")),
                Acessivel = r.GetBoolean(r.GetOrdinal("Acessivel")),
                Descricao = r["Descricao"] as string,
                Comodidades = r["Comodidades"] as string
            });
        return lista;
    }

    public async Task<List<Disponibilidade>> BuscarAsync(DateTime entrada, DateTime saida, int hospedes)
    {
        var lista = new List<Disponibilidade>();
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_BuscarDisponibilidade");
        cmd.Parameters.Add("@Entrada", SqlDbType.Date).Value = entrada.Date;
        cmd.Parameters.Add("@Saida", SqlDbType.Date).Value = saida.Date;
        cmd.Parameters.Add("@Hospedes", SqlDbType.TinyInt).Value = (byte)hospedes;
        await using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
            lista.Add(new Disponibilidade
            {
                IdTipoQuarto = r.GetInt32(r.GetOrdinal("IdTipoQuarto")),
                Nome = r.GetString(r.GetOrdinal("Nome")),
                Capacidade = r.GetByte(r.GetOrdinal("Capacidade")),
                PrecoDiaria = r.GetDecimal(r.GetOrdinal("PrecoDiaria")),
                ValorTotal = r.GetDecimal(r.GetOrdinal("ValorTotal")),
                QuartosLivres = r.GetInt32(r.GetOrdinal("QuartosLivres"))
            });
        return lista;
    }

    public async Task<string> CriarReservaAsync(ReservaInput m)
    {
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_CriarReserva");
        cmd.Parameters.Add("@Nome", SqlDbType.NVarChar, 120).Value = m.Nome.Trim();
        cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 160).Value = m.Email.Trim().ToLowerInvariant();
        cmd.Parameters.Add("@Telefone", SqlDbType.VarChar, 20).Value = m.Telefone.Trim();
        cmd.Parameters.Add("@IdTipoQuarto", SqlDbType.Int).Value = m.IdTipoQuarto;
        cmd.Parameters.Add("@Entrada", SqlDbType.Date).Value = m.Entrada.Date;
        cmd.Parameters.Add("@Saida", SqlDbType.Date).Value = m.Saida.Date;
        cmd.Parameters.Add("@Hospedes", SqlDbType.TinyInt).Value = (byte)m.Hospedes;
        var cod = new SqlParameter("@Codigo", SqlDbType.VarChar, 10) { Direction = ParameterDirection.Output };
        cmd.Parameters.Add(cod);
        await cmd.ExecuteNonQueryAsync();
        return (string)cod.Value;
    }

    public async Task<ReservaInfo?> ConsultarAsync(string codigo, string email)
    {
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_ConsultarReserva");
        cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 10).Value = codigo.Trim().ToUpperInvariant();
        cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 160).Value = email.Trim().ToLowerInvariant();
        await using var r = await cmd.ExecuteReaderAsync();
        if (!await r.ReadAsync()) return null;
        return new ReservaInfo
        {
            Codigo = r.GetString(r.GetOrdinal("Codigo")),
            Tipo = r.GetString(r.GetOrdinal("Tipo")),
            DataEntrada = r.GetDateTime(r.GetOrdinal("DataEntrada")),
            DataSaida = r.GetDateTime(r.GetOrdinal("DataSaida")),
            Noites = r.GetInt32(r.GetOrdinal("Noites")),
            QtdHospedes = r.GetByte(r.GetOrdinal("QtdHospedes")),
            ValorTotal = r.GetDecimal(r.GetOrdinal("ValorTotal")),
            ValorPago = r.GetDecimal(r.GetOrdinal("ValorPago")),
            Status = r.GetString(r.GetOrdinal("Status"))
        };
    }

    /// <returns>true se o cancelamento foi gratuito (7+ dias antes da entrada).</returns>
    public async Task<bool> CancelarAsync(string codigo, string email)
    {
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_CancelarReservaHospede");
        cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 10).Value = codigo.Trim().ToUpperInvariant();
        cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 160).Value = email.Trim().ToLowerInvariant();
        var g = new SqlParameter("@Gratuito", SqlDbType.Bit) { Direction = ParameterDirection.Output };
        cmd.Parameters.Add(g);
        await cmd.ExecuteNonQueryAsync();
        return (bool)g.Value;
    }

    public async Task EnviarMensagemAsync(ContatoModel m)
    {
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_RegistrarMensagem");
        cmd.Parameters.Add("@Nome", SqlDbType.NVarChar, 120).Value = m.Nome.Trim();
        cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 160).Value = m.Email.Trim();
        cmd.Parameters.Add("@Texto", SqlDbType.NVarChar, 1000).Value = m.Texto.Trim();
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<AdminUser?> ObterAdminAsync(string login)
    {
        await using var c = _db.Site(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_ObterAdmin");
        cmd.Parameters.Add("@Login", SqlDbType.VarChar, 40).Value = login.Trim();
        await using var r = await cmd.ExecuteReaderAsync();
        if (!await r.ReadAsync()) return null;
        return new AdminUser
        {
            IdUsuario = r.GetInt32(r.GetOrdinal("IdUsuario")),
            Login = r.GetString(r.GetOrdinal("Login")),
            SenhaHash = (byte[])r["SenhaHash"],
            Salt = (byte[])r["Salt"],
            Perfil = r.GetString(r.GetOrdinal("Perfil"))
        };
    }
}
