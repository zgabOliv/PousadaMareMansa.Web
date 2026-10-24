using System.Security.Cryptography;
namespace PousadaMareMansa.Web.Services;

/// <summary>PBKDF2-SHA256 com salt aleatório (hash de 32 bytes cabe em VARBINARY(64)).</summary>
public static class PasswordHasher
{
    private const int Iteracoes = 100_000;
    public static (byte[] Hash, byte[] Salt) Gerar(string senha)
    {
        var salt = RandomNumberGenerator.GetBytes(32);
        return (Derivar(senha, salt), salt);
    }
    public static bool Verificar(string senha, byte[] hash, byte[] salt) =>
        CryptographicOperations.FixedTimeEquals(Derivar(senha, salt), hash);
    private static byte[] Derivar(string senha, byte[] salt) =>
        Rfc2898DeriveBytes.Pbkdf2(senha, salt, Iteracoes, HashAlgorithmName.SHA256, 32);
}
