using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PousadaMareMansa.Web.Data;
using PousadaMareMansa.Web.Models;
using PousadaMareMansa.Web.Services;
namespace PousadaMareMansa.Web.Controllers;

[Authorize]
public class AdminController : Controller
{
    private readonly PousadaRepository _site;
    private readonly AdminRepository _admin;
    public AdminController(PousadaRepository site, AdminRepository admin) { _site = site; _admin = admin; }

    [AllowAnonymous, HttpGet] public IActionResult Login() => View(new LoginModel());

    [AllowAnonymous, HttpPost]
    public async Task<IActionResult> Login(LoginModel m)
    {
        if (!ModelState.IsValid) return View(m);
        var u = await _site.ObterAdminAsync(m.Login);
        // Mensagem única para usuário inexistente e senha errada (não revela qual falhou).
        if (u is null || !PasswordHasher.Verificar(m.Senha, u.SenhaHash, u.Salt))
        {
            ModelState.AddModelError("", "Usuário ou senha incorretos.");
            return View(m);
        }
        var id = new ClaimsIdentity(new[] { new Claim(ClaimTypes.Name, u.Login), new Claim(ClaimTypes.Role, u.Perfil) },
            CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(new ClaimsPrincipal(id));
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync();
        return RedirectToAction("Index", "Home");
    }

    public async Task<IActionResult> Index() => View(await _admin.ListarReservasAsync());

    [HttpPost]
    public async Task<IActionResult> Pagar(string codigo, decimal valor, string forma)
    {
        try { await _admin.PagarAsync(codigo, valor, forma); TempData["Ok"] = "Pagamento registrado."; }
        catch (SqlException ex) { TempData["Erro"] = ex.Number >= 50000 ? ex.Message : "Erro ao registrar pagamento."; }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> CancelarReserva(string codigo)
    {
        try { await _admin.CancelarAsync(codigo); TempData["Ok"] = "Reserva cancelada."; }
        catch (SqlException ex) { TempData["Erro"] = ex.Number >= 50000 ? ex.Message : "Erro ao cancelar."; }
        return RedirectToAction(nameof(Index));
    }
}
