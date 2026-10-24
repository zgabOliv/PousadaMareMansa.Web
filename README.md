# Pousada Maré Mansa: site em ASP.NET Core MVC (PIM IV)

## Passo a passo
1. No SQL Server, execute `Database/01_banco.sql` e depois `Database/02_procedures_mvc.sql`.
2. Crie os usuários de banco (comentário no final do 02) e troque as senhas.
3. Coloque as connection strings (sem versionar senhas):
   `dotnet user-secrets init`
   `dotnet user-secrets set "ConnectionStrings:Site" "Server=...;Database=PousadaMareMansa;User Id=app_site;Password=...;TrustServerCertificate=True"`
   `dotnet user-secrets set "ConnectionStrings:Admin" "Server=...;Database=PousadaMareMansa;User Id=app_admin;Password=...;TrustServerCertificate=True"`
4. Crie o primeiro administrador: `dotnet run -- --criar-admin gerente SuaSenhaForte1 Gerente`
5. Execute: `dotnet run` e abra o endereço mostrado no terminal.

## Arquitetura (Etapa 6)
- **Models**: classes de dados e validação (DataAnnotations).
- **Data**: `Db` (conexões), `PousadaRepository` e `AdminRepository`. Só chamam stored procedures.
- **Controllers**: Home, Reserva e Admin. Recebem a requisição, validam e chamam o repositório.
- **Views**: Razor (.cshtml) com layout compartilhado.
- **Services**: `PasswordHasher` (PBKDF2-SHA256 com salt).

## Segurança aplicada
- Conexão do site no papel `rl_site` (só executa procedures, sem acesso às tabelas).
- Consultas parametrizadas (sem concatenar SQL), token anti-CSRF em todos os POST.
- Senhas de administrador com hash e salt, cookie HttpOnly, mesma mensagem para usuário ou senha inválidos.
- Cancelamento pelo hóspede exige código e e-mail da reserva.
