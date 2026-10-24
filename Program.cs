using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using PousadaMareMansa.Web.Data;
using PousadaMareMansa.Web.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews(o => o.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddSingleton<Db>();
builder.Services.AddScoped<PousadaRepository>();
builder.Services.AddScoped<AdminRepository>();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(o =>
    {
        o.LoginPath = "/Admin/Login";
        o.Cookie.HttpOnly = true;
        o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        o.ExpireTimeSpan = TimeSpan.FromHours(2);
    });

var app = builder.Build();

// Uso: dotnet run -- --criar-admin <login> <senha> <Gerente|Recepcao>
if (args.Length == 4 && args[0] == "--criar-admin")
{
    using var escopo = app.Services.CreateScope();
    var (hash, salt) = PasswordHasher.Gerar(args[2]);
    await escopo.ServiceProvider.GetRequiredService<AdminRepository>().CriarAdminAsync(args[1], hash, salt, args[3]);
    Console.WriteLine("Administrador criado.");
    return;
}

if (!app.Environment.IsDevelopment()) { app.UseExceptionHandler("/Home/Erro"); app.UseHsts(); }
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");
app.Run();
