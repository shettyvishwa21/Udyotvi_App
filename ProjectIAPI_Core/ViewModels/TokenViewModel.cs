namespace ProjectIAPI_Core.ViewModels
{
    public class TokenSettings
    {
        public string? SecretKey { get; set; }
        public string? Issuer { get; set; }
        public string? Audience { get; set; }
        public int RefreshTokenExpireTimeInMinutes { get; set; }
    }
}