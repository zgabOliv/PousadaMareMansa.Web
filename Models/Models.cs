using System.ComponentModel.DataAnnotations;
namespace PousadaMareMansa.Web.Models;

public class TipoQuarto
{
    public int IdTipoQuarto { get; set; }
    public string Nome { get; set; } = "";
    public byte Capacidade { get; set; }
    public decimal PrecoDiaria { get; set; }
    public bool Acessivel { get; set; }
    public string? Descricao { get; set; }
    public string? Comodidades { get; set; }
}

public class Disponibilidade
{
    public int IdTipoQuarto { get; set; }
    public string Nome { get; set; } = "";
    public byte Capacidade { get; set; }
    public decimal PrecoDiaria { get; set; }
    public decimal ValorTotal { get; set; }
    public int QuartosLivres { get; set; }
}

public class BuscaModel
{
    [Required(ErrorMessage = "Informe a data de entrada.")][DataType(DataType.Date)] public DateTime? Entrada { get; set; }
    [Required(ErrorMessage = "Informe a data de saída.")][DataType(DataType.Date)] public DateTime? Saida { get; set; }
    [Range(1, 8, ErrorMessage = "Informe de 1 a 8 hóspedes.")] public int Hospedes { get; set; } = 2;
}

public class BuscaResultado
{
    public BuscaModel Busca { get; set; } = new();
    public List<Disponibilidade> Itens { get; set; } = new();
    public int Noites { get; set; }
}

public class ReservaInput
{
    public int IdTipoQuarto { get; set; }
    [DataType(DataType.Date)] public DateTime Entrada { get; set; }
    [DataType(DataType.Date)] public DateTime Saida { get; set; }
    public int Hospedes { get; set; }
    [Required(ErrorMessage = "Informe seu nome."), StringLength(120, MinimumLength = 3, ErrorMessage = "O nome deve ter ao menos 3 letras.")] public string Nome { get; set; } = "";
    [Required(ErrorMessage = "Informe seu e-mail."), EmailAddress(ErrorMessage = "E-mail inválido."), StringLength(160)] public string Email { get; set; } = "";
    [Required(ErrorMessage = "Informe seu WhatsApp."), StringLength(20), Display(Name = "WhatsApp")] public string Telefone { get; set; } = "";
}

public class ReservaInfo
{
    public string Codigo { get; set; } = "";
    public string Tipo { get; set; } = "";
    public DateTime DataEntrada { get; set; }
    public DateTime DataSaida { get; set; }
    public int Noites { get; set; }
    public int QtdHospedes { get; set; }
    public decimal ValorTotal { get; set; }
    public decimal ValorPago { get; set; }
    public string Status { get; set; } = "";
}

public class ConsultaModel
{
    [Required(ErrorMessage = "Informe o código da reserva.")] public string Codigo { get; set; } = "";
    [Required(ErrorMessage = "Informe o e-mail usado na reserva."), EmailAddress(ErrorMessage = "E-mail inválido.")] public string Email { get; set; } = "";
    public ReservaInfo? Info { get; set; }
}

public class ContatoModel
{
    [Required(ErrorMessage = "Informe seu nome."), StringLength(120)] public string Nome { get; set; } = "";
    [Required(ErrorMessage = "Informe seu e-mail."), EmailAddress(ErrorMessage = "E-mail inválido."), StringLength(160)] public string Email { get; set; } = "";
    [Required(ErrorMessage = "Escreva sua mensagem."), StringLength(1000, MinimumLength = 5, ErrorMessage = "A mensagem deve ter de 5 a 1000 caracteres.")] public string Texto { get; set; } = "";
}

public class LoginModel
{
    [Required(ErrorMessage = "Informe o usuário.")] public string Login { get; set; } = "";
    [Required(ErrorMessage = "Informe a senha."), DataType(DataType.Password)] public string Senha { get; set; } = "";
}

public class AdminUser
{
    public int IdUsuario { get; set; }
    public string Login { get; set; } = "";
    public byte[] SenhaHash { get; set; } = Array.Empty<byte>();
    public byte[] Salt { get; set; } = Array.Empty<byte>();
    public string Perfil { get; set; } = "";
}

public class ReservaAdmin
{
    public string Codigo { get; set; } = "";
    public string Hospede { get; set; } = "";
    public string Quarto { get; set; } = "";
    public string Tipo { get; set; } = "";
    public DateTime DataEntrada { get; set; }
    public DateTime DataSaida { get; set; }
    public decimal ValorTotal { get; set; }
    public decimal ValorPago { get; set; }
    public string Status { get; set; } = "";
}
