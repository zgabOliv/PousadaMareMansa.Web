using System.Data;
using Microsoft.Data.SqlClient;
using PousadaMareMansa.Web.Models;
namespace PousadaMareMansa.Web.Data;

/// <summary>Acesso a dados da área administrativa (conexão com papel rl_gerente).</summary>
public class AdminRepository
{
    private readonly Db _db;
    public AdminRepository(Db db) => _db = db;

    public async Task<List<ReservaAdmin>> ListarReservasAsync()
    {
        var lista = new List<ReservaAdmin>();
        await using var c = _db.Admin(); await c.OpenAsync();
        await using var cmd = new SqlCommand(
            "SELECT Codigo, Hospede, Quarto, Tipo, DataEntrada, DataSaida, ValorTotal, ValorPago, Status " +
            "FROM vw_ReservasDetalhadas ORDER BY DataEntrada DESC", c);
        await using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
            lista.Add(new ReservaAdmin
            {
                Codigo = r.GetString(0), Hospede = r.GetString(1), Quarto = r.GetString(2), Tipo = r.GetString(3),
                DataEntrada = r.GetDateTime(4), DataSaida = r.GetDateTime(5),
                ValorTotal = r.GetDecimal(6), ValorPago = r.GetDecimal(7), Status = r.GetString(8)
            });
        return lista;
    }

    public async Task PagarAsync(string codigo, decimal valor, string forma)
    {
        await using var c = _db.Admin(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_RegistrarPagamento");
        cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 10).Value = codigo;
        var v = cmd.Parameters.Add("@Valor", SqlDbType.Decimal);
        v.Precision = 10; v.Scale = 2; v.Value = valor;
        cmd.Parameters.Add("@Forma", SqlDbType.VarChar, 10).Value = forma;
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task CancelarAsync(string codigo)
    {
        await using var c = _db.Admin(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_CancelarReserva");
        cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 10).Value = codigo;
        cmd.Parameters.Add(new SqlParameter("@Gratuito", SqlDbType.Bit) { Direction = ParameterDirection.Output });
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task CriarAdminAsync(string login, byte[] hash, byte[] salt, string perfil)
    {
        await using var c = _db.Admin(); await c.OpenAsync();
        await using var cmd = Db.Proc(c, "sp_CriarAdmin");
        cmd.Parameters.Add("@Login", SqlDbType.VarChar, 40).Value = login;
        cmd.Parameters.Add("@Hash", SqlDbType.VarBinary, 64).Value = hash;
        cmd.Parameters.Add("@Salt", SqlDbType.VarBinary, 32).Value = salt;
        cmd.Parameters.Add("@Perfil", SqlDbType.VarChar, 15).Value = perfil;
        await cmd.ExecuteNonQueryAsync();
    }
}
