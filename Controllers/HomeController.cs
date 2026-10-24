using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PousadaMareMansa.Web.Data;
using PousadaMareMansa.Web.Models;
namespace PousadaMareMansa.Web.Controllers;

public class HomeController : Controller
{
    private readonly PousadaRepository _repo;
    public HomeController(PousadaRepository repo) => _repo = repo;

    public async Task<IActionResult> Index() => View(await _repo.ListarTiposAsync());

    [HttpGet] public IActionResult Contato() => View(new ContatoModel());

    [HttpPost]
    public async Task<IActionResult> Contato(ContatoModel m)
    {
        if (!ModelState.IsValid) return View(m);
        try { await _repo.EnviarMensagemAsync(m); }
        catch (SqlException) { ModelState.AddModelError("", "Não foi possível enviar agora. Tente novamente em instantes."); return View(m); }
        TempData["Ok"] = "Mensagem enviada. Respondemos no mesmo dia.";
        return RedirectToAction(nameof(Contato));
    }

    public IActionResult Erro() => View();
}
