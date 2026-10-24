using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PousadaMareMansa.Web.Data;
using PousadaMareMansa.Web.Models;
namespace PousadaMareMansa.Web.Controllers;

public class ReservaController : Controller
{
    private readonly PousadaRepository _repo;
    public ReservaController(PousadaRepository repo) => _repo = repo;

    // Erros 50000+ vêm das regras da procedure (THROW) e têm mensagem segura para o usuário.
    private void AddErro(SqlException ex) =>
        ModelState.AddModelError("", ex.Number >= 50000 ? ex.Message : "Erro ao acessar o sistema. Tente novamente.");

    [HttpGet]
    public async Task<IActionResult> Buscar(BuscaModel m)
    {
        var r = new BuscaResultado { Busca = m };
        if (!ModelState.IsValid || m.Entrada is null || m.Saida is null) return View(r);
        try
        {
            r.Noites = (m.Saida.Value.Date - m.Entrada.Value.Date).Days;
            r.Itens = await _repo.BuscarAsync(m.Entrada.Value, m.Saida.Value, m.Hospedes);
        }
        catch (SqlException ex) { AddErro(ex); }
        return View(r);
    }

    [HttpGet]
    public IActionResult Reservar(ReservaInput m) { ModelState.Clear(); return View(m); }

    [HttpPost, ActionName("Reservar")]
    public async Task<IActionResult> ReservarPost(ReservaInput m)
    {
        if (!ModelState.IsValid) return View(m);
        try
        {
            var codigo = await _repo.CriarReservaAsync(m);
            return RedirectToAction(nameof(Confirmacao), new { codigo });
        }
        catch (SqlException ex) { AddErro(ex); return View(m); }
    }

    public IActionResult Confirmacao(string codigo) => View((object)codigo);

    [HttpGet] public IActionResult Consultar() => View(new ConsultaModel());

    [HttpPost]
    public async Task<IActionResult> Consultar(ConsultaModel m)
    {
        if (!ModelState.IsValid) return View(m);
        try
        {
            m.Info = await _repo.ConsultarAsync(m.Codigo, m.Email);
            if (m.Info is null) ModelState.AddModelError("", "Nenhuma reserva encontrada com esse código e e-mail.");
        }
        catch (SqlException ex) { AddErro(ex); }
        return View(m);
    }

    [HttpPost]
    public async Task<IActionResult> Cancelar(string codigo, string email)
    {
        try
        {
            var gratis = await _repo.CancelarAsync(codigo, email);
            TempData["Ok"] = gratis ? "Reserva cancelada sem custos." : "Reserva cancelada. Como faltam menos de 7 dias, entre em contato sobre eventuais valores.";
        }
        catch (SqlException ex) { TempData["Erro"] = ex.Number >= 50000 ? ex.Message : "Erro ao cancelar."; }
        return RedirectToAction(nameof(Consultar));
    }
}
