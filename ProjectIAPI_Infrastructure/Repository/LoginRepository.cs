using Dapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Npgsql;
using ProjectIAPI_Core.Interfaces;
using ProjectIAPI_Core.ViewModels;
using ProjectIAPI_Infrastructure.Helper;
using ProjectIAPI_Infrastructure.Models;
using System.Data;
using System.Threading.Tasks;

namespace ProjectIAPI_Infrastructure.Repository
{
    public class LoginRepository : ILoginRepository
    {
        private readonly DataBaseContext _dbContext;
        private CommonHelper _helper = new CommonHelper();
        private readonly string _connectionString;

        public LoginRepository(DataBaseContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _connectionString = _dbContext.Database.GetConnectionString()
                 ?? throw new InvalidOperationException("Connection string is not configured in DataBaseContext");
        }

        public async Task<ValidateLoginResult> Validateuser(Login login)
        {
            ValidateLoginResult validateLoginResult = new ValidateLoginResult();
            try
            {
                var encryptedpassword = _helper.EncryptPassword(login.Password);
                var result = await _dbContext.Set<fn_validate_account>()
                    .FromSqlRaw("SELECT * FROM public.fn_validate_account(:ip_email_or_phone, :ip_password, :ip_is_sso_login)",
                        new NpgsqlParameter("ip_email_or_phone", login.Email ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_password", encryptedpassword),
                        new NpgsqlParameter("ip_is_sso_login", login.IsSsoUser))
                    .FirstOrDefaultAsync();

                if (result != null)
                {
                    validateLoginResult.ResultMessage = result.resultmessage;
                    validateLoginResult.ResultType = result.resulttype;
                    validateLoginResult.UserID = result.user_id ?? 0;
                }
                else
                {
                    validateLoginResult.ResultMessage = "No result returned from database";
                    validateLoginResult.ResultType = 0;
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                validateLoginResult.ResultMessage = "Database error: " + ex.Message;
                validateLoginResult.ResultType = 0;
            }
            return validateLoginResult;
        }

        public async Task<ValidateForgotPasswordResult> ValidateForgotPassword(ForgotPassword forgotPassword)
        {
            var validateForgotPasswordResult = new ValidateForgotPasswordResult();

            try
            {
                using (var connection = new NpgsqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    var parameters = new
                    {
                        ip_email = forgotPassword.Email
                    };

                    var result = await connection.QuerySingleOrDefaultAsync<fn_forget_password>(
                        "SELECT * FROM public.fn_forgot_password(@ip_email)",
                        parameters);

                    if (result != null)
                    {
                        validateForgotPasswordResult.ResultMessage = result.result_message;
                        validateForgotPasswordResult.ResultType = result.result_type;

                        string encryptedTempPassword = _helper.EncryptPassword(result.temp_password);

                        await connection.ExecuteAsync(
                            @"UPDATE m_user
                              SET password = @EncryptedPassword,
                                  is_reset = TRUE,
                                  updated_on = CURRENT_TIMESTAMP,
                                  updated_by = @UserId
                              WHERE id = @UserId",
                            new { EncryptedPassword = encryptedTempPassword, UserId = result.user_id });

                        validateForgotPasswordResult.TempPassword = result.temp_password;
                        validateForgotPasswordResult.UserId = result.user_id.ToString();
                    }
                    else
                    {
                        validateForgotPasswordResult.ResultMessage = "No result returned from database";
                        validateForgotPasswordResult.ResultType = 0;
                    }
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                validateForgotPasswordResult.ResultMessage = $"Error: {ex.Message}";
                validateForgotPasswordResult.ResultType = 0;
            }

            return validateForgotPasswordResult;
        }

        public async Task<ChangePasswordResult> ChangePassword(ChangePasswordRequest request)
        {
            var result = new ChangePasswordResult();
            try
            {
                var encryptedCurrentPassword = _helper.EncryptPassword(request.CurrentPassword);
                var encryptedNewPassword = _helper.EncryptPassword(request.NewPassword);

                var fnResult = await _dbContext.Set<fn_change_password>()
                    .FromSqlRaw("SELECT * FROM public.fn_change_password(:ip_user_id, :ip_current_password, :ip_new_password)",
                        new NpgsqlParameter("ip_user_id", request.UserId),
                        new NpgsqlParameter("ip_current_password", encryptedCurrentPassword),
                        new NpgsqlParameter("ip_new_password", encryptedNewPassword))
                    .FirstOrDefaultAsync();

                if (fnResult != null)
                {
                    result.ResultMessage = fnResult.result_message;
                    result.ResultType = fnResult.result_type;
                }
                else
                {
                    result.ResultMessage = "No result returned from database";
                    result.ResultType = 0;
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                result.ResultMessage = "Database error: " + ex.Message;
                result.ResultType = 0;
            }
            return result;
        }
    }
}