using System.Data;
using Microsoft.Data.SqlClient;
namespace PousadaMareMansa.Web.Data;

/// <summary>Fábrica de conexões. "Site" usa o papel rl_site; "Admin" usa rl_gerente.</summary>
public class Db
{
    private readonly IConfiguration _cfg;
    public Db(IConfiguration cfg) => _cfg = cfg;
    public SqlConnection Site() => new(_cfg.GetConnectionString("Site"));
    public SqlConnection Admin() => new(_cfg.GetConnectionString("Admin"));

    public static SqlCommand Proc(SqlConnection c, string nome) =>
        new(nome, c) { CommandType = CommandType.StoredProcedure };
}
