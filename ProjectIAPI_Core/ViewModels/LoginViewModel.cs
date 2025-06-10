using System.ComponentModel.DataAnnotations;

namespace ProjectIAPI_Core.ViewModels
{
    public class Login
    {
        /// <summary>
        /// The email or phone number of the user.
        /// </summary>
        [Required(ErrorMessage = "Email or phone number is required")]
        public string? Email { get; set; } = string.Empty;

        /// <summary>
        /// The password of the user.
        /// </summary>
        [Required(ErrorMessage = "Password is required")]
        public string? Password { get; set; } = string.Empty;

        /// <summary>
        /// Indicates if the login is via SSO.
        /// </summary>
        public bool IsSsoUser { get; set; } = false;
    }

    public class ValidateLoginResult
    {
        public int ResultType { get; set; } = 0;
        public string? ResultMessage { get; set; } = string.Empty;
        public long UserID { get; set; } = 0;
    }
}