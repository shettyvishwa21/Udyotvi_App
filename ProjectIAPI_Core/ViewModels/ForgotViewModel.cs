using System.ComponentModel.DataAnnotations;


namespace ProjectIAPI_Core.ViewModels
{
    public class ForgotPassword
    {
        [Required]
        public string Email { get; set; } = string.Empty;




    }




    public class ValidateForgotPasswordResult
    {
        public int ResultType { get; set; } = 0;
        public string ResultMessage { get; set; } = string.Empty;
        public string TempPassword { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;




    }


}
