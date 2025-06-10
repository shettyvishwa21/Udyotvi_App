using ProjectIAPI_Core.ViewModels;

namespace ProjectIAPI_Core.Interfaces
{
    public interface ILoginRepository
    {
        Task<ValidateLoginResult> Validateuser(Login login);
        Task<ValidateForgotPasswordResult> ValidateForgotPassword(ForgotPassword forgotPassword);
        Task<ChangePasswordResult> ChangePassword(ChangePasswordRequest request);
    }
}