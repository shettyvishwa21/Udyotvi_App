using Microsoft.AspNetCore.Mvc;
using ProjectIAPI_Core.Interfaces;
using ProjectIAPI_Core.ViewModels;

namespace ProjectIAPI.Controllers
{
[Route("api/auth")]
[ApiController]
public class LoginController : BaseController
{
    ILoginRepository _iLoginRepository;
    private readonly ILogger<LoginController> _logger;

    public LoginController(ILoginRepository iLoginRepository, ILogger<LoginController> logger) : base(logger)
    {
        this._iLoginRepository = iLoginRepository;
        this._logger = logger;
    }

    [Route("token")]
    [HttpPost]
    public async Task<IActionResult> GetLoginToken([FromBody] Login login)
    {
        APIResponse _apiResponse = new APIResponse();
        _logger.LogInformation("Login attempt with email/phone: {Email}, SSO: {IsSsoUser}, {Password}", login.Email, login.IsSsoUser, login.Password);
        try
        {
            if (!ModelState.IsValid)
            {
                _apiResponse.ResultMessage = "Invalid inputs";
                _apiResponse.ResultType = 0;
                _logger.LogWarning("Model state invalid: {Errors}", ModelState);
                return BadRequest(_apiResponse);
            }
            if (string.IsNullOrEmpty(login.Email) || string.IsNullOrEmpty(login.Password))
            {
                _apiResponse.ResultMessage = "Email or phone number and password are required";
                _apiResponse.ResultType = 0;
                _logger.LogWarning("Email or password missing: {Email}", login.Email);
                return BadRequest(_apiResponse);
            }
            var validateUser = await _iLoginRepository.Validateuser(login);
            _apiResponse.ResultMessage = validateUser.ResultMessage ?? "Validation failed";
            _apiResponse.ResultType = validateUser.ResultType;
            _apiResponse.ResultData = validateUser.UserID;
            
            if (validateUser.ResultType == 0)
                {
                    _logger.LogWarning("Validation failed: {Message}", _apiResponse.ResultMessage);
                    return BadRequest(_apiResponse);
                }
            _logger.LogInformation("Login response for: {Email}, ResultType: {ResultType}", login.Email, validateUser.ResultType);
            return Ok(_apiResponse);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for {Email}", login.Email);
            return HandleException(ex);
        }
    }

    [Route("forgot-password")]
    [HttpPost]
    public async Task<IActionResult> GetForgotPassword(ForgotPassword forgotPassword)
    {
        APIResponse _apiResponse = new APIResponse();
        try
        {
            if (!ModelState.IsValid)
            {
                _apiResponse.ResultMessage = "Invalid inputs";
                _apiResponse.ResultType = 0;
                return BadRequest(_apiResponse);
            }
            if (string.IsNullOrEmpty(forgotPassword.Email))
            {
                _apiResponse.ResultMessage = "Email is required";
                _apiResponse.ResultType = 0;
                return BadRequest(_apiResponse);
            }
            var forgotResult = await _iLoginRepository.ValidateForgotPassword(forgotPassword);
            if (forgotResult.ResultType == 0)
            {
                _apiResponse.ResultMessage = forgotResult.ResultMessage;
                _apiResponse.ResultType = 0;
                return BadRequest(_apiResponse);
            }
            _apiResponse.ResultData = new
            {
                TempPassword = forgotResult.TempPassword,
                UserId = forgotResult.UserId
            };
            _apiResponse.ResultMessage = forgotResult.ResultMessage;
            _apiResponse.ResultType = 1;
            return Ok(_apiResponse);
        }
        catch (Exception ex)
        {
            return HandleException(ex);
        }
    }

    [Route("change-password")]
    [HttpPost]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        APIResponse _apiResponse = new APIResponse();
        _logger.LogInformation("Change password attempt for user ID: {UserId}", request.UserId);
        try
        {
            if (!ModelState.IsValid)
            {
                _apiResponse.ResultMessage = "Invalid inputs";
                _apiResponse.ResultType = 0;
                _logger.LogWarning("Model state invalid: {Errors}", ModelState);
                return BadRequest(_apiResponse);
            }
            if (request.UserId <= 0 || string.IsNullOrEmpty(request.CurrentPassword) || string.IsNullOrEmpty(request.NewPassword))
            {
                _apiResponse.ResultMessage = "User ID, current password, and new password are required";
                _apiResponse.ResultType = 0;
                _logger.LogWarning("Missing inputs for user ID: {UserId}", request.UserId);
                return BadRequest(_apiResponse);
            }
            var changeResult = await _iLoginRepository.ChangePassword(request);
            if (changeResult.ResultType == 0)
            {
                _apiResponse.ResultMessage = changeResult.ResultMessage;
                _apiResponse.ResultType = 0;
                _logger.LogWarning("Change password failed: {Message}", changeResult.ResultMessage);
                return BadRequest(_apiResponse);
            }
            _apiResponse.ResultMessage = changeResult.ResultMessage;
            _apiResponse.ResultType = 1;
            _logger.LogInformation("Password changed successfully for user ID: {UserId}", request.UserId);
            return Ok(_apiResponse);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during change password for user ID: {UserId}", request.UserId);
                return HandleException(ex);
        }
    }
}
}