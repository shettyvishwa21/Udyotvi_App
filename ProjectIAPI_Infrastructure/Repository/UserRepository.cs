using Microsoft.EntityFrameworkCore;
using Npgsql;
using ProjectIAPI_Core.Interfaces;
using ProjectIAPI_Core.ViewModels;
using ProjectIAPI_Infrastructure.Helper;
using ProjectIAPI_Infrastructure.Models;
using System.Text.Json;
using NpgsqlTypes;

namespace ProjectIAPI_Infrastructure.Repository
{
    public class UserRepository : IUserRepository
    {
        private readonly DataBaseContext _dbContext;
        private readonly CommonHelper _helper = new CommonHelper();

        public UserRepository(DataBaseContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public async Task<RegisterResult> RegisterUser(RegisterRequest request)
        {
            try
            {
                var result = await _dbContext.Set<RegisterResult>()
                    .FromSqlRaw("SELECT * FROM public.fn_register_user(:ip_first_name, :ip_last_name, :ip_email, :ip_phone_number, :ip_gender)",
                        new NpgsqlParameter("ip_first_name", request.FirstName),
                        new NpgsqlParameter("ip_last_name", request.LastName),
                        new NpgsqlParameter("ip_email", request.Email),
                        new NpgsqlParameter("ip_phone_number", request.PhoneNumber),
                        new NpgsqlParameter("ip_gender", request.Gender))
                    .FirstOrDefaultAsync();

                return result ?? new RegisterResult 
                { 
                    ResultType = 0, 
                    ResultMessage = "Registration failed: Unknown error" 
                };
            }
            catch (Exception ex)
            {
                return new RegisterResult
                {
                    ResultType = 0,
                    ResultMessage = $"Registration failed: {ex.Message}"
                };
            }
        }

        public async Task<UpsertUserResult> UpsertUser(UserUpsert user)
        {
            UpsertUserResult upsertUserResult = new UpsertUserResult();
            try
            {
                var encryptedPassword = string.IsNullOrEmpty(user.Password) ? user.Password : _helper.EncryptPassword(user.Password);
                var result = await _dbContext.Set<fn_m_user_insert_update>()
                    .FromSqlRaw("SELECT * FROM public.fn_m_user_insert_update(:ip_id, :ip_first_name, :ip_last_name, :ip_phone_number, :ip_email, :ip_password, :ip_account_type, :ip_gender, :ip_profile_pic, :ip_bio, :ip_location, :ip_created_by, :ip_is_active, :ip_is_deleted, :ip_is_sso_user, :ip_social_link)",
                        new NpgsqlParameter("ip_id", user.Id),
                        new NpgsqlParameter("ip_first_name", user.FirstName ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_last_name", user.LastName ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_phone_number", user.PhoneNumber ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_email", user.Email ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_password", encryptedPassword ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_account_type", user.UserType),
                        new NpgsqlParameter("ip_gender", user.Gender),
                        new NpgsqlParameter("ip_profile_pic", user.ProfilePic ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_bio", user.Bio ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_location", user.Location ?? (object)DBNull.Value),
                        new NpgsqlParameter("ip_created_by", user.CreatedBy),
                        new NpgsqlParameter("ip_is_active", user.IsActive),
                        new NpgsqlParameter("ip_is_deleted", user.IsDeleted),
                        new NpgsqlParameter("ip_is_sso_user", user.IsSsoUser),
                        new NpgsqlParameter("ip_social_link", user.SocialLink ?? (object)DBNull.Value)
                    ).FirstOrDefaultAsync();

                if (result != null)
                {
                    upsertUserResult.ResultMessage = result.resultmessage;
                    upsertUserResult.ResultType = result.resulttype;
                    upsertUserResult.UserId = result.userid ?? 0; // Handle NULL userid
                }
                else
                {
                    upsertUserResult.ResultMessage = "No result returned from database";
                    upsertUserResult.ResultType = 0;
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                upsertUserResult.ResultMessage = "Database error: " + ex.Message;
                upsertUserResult.ResultType = 0;
            }
            return upsertUserResult;
        }

        public async Task<UpsertEducationResult> UpsertEducation(EducationUpsert education)
        {
            UpsertEducationResult upsertEducationResult = new UpsertEducationResult();
            try
            {
                // Serialize EducationData to JSONB
                var educationDataJson = JsonSerializer.Serialize(education.EducationData);

                var result = await _dbContext.Set<fn_education_insert_update>()
                    .FromSqlRaw("SELECT * FROM public.fn_education_insert_update(:ip_user_id, :ip_education_data)",
                        new NpgsqlParameter("ip_user_id", education.UserId),
                        new NpgsqlParameter("ip_education_data", educationDataJson) { NpgsqlDbType = NpgsqlTypes.NpgsqlDbType.Jsonb })
                    .FirstOrDefaultAsync();

                if (result != null)
                {
                    upsertEducationResult.ResultMessage = result.resultmessage;
                    upsertEducationResult.ResultType = result.resulttype;
                    upsertEducationResult.UserId = result.userid ?? 0;
                }
                else
                {
                    upsertEducationResult.ResultMessage = "No result returned from database";
                    upsertEducationResult.ResultType = 0;
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                upsertEducationResult.ResultMessage = "Database error: " + ex.Message;
                upsertEducationResult.ResultType = 0;
            }
            return upsertEducationResult;
        }

        public async Task<UpsertExperienceResult> UpsertExperience(ExperienceUpsert experience)
        {
            UpsertExperienceResult upsertExperienceResult = new UpsertExperienceResult();
            try
            {
                // Serialize ExperienceData to JSONB
                var experienceDataJson = JsonSerializer.Serialize(experience.ExperienceData);

                var result = await _dbContext.Set<fn_experience_insert_update>()
                    .FromSqlRaw("SELECT * FROM public.fn_experience_insert_update(:ip_user_id, :ip_experience_data)",
                        new NpgsqlParameter("ip_user_id", experience.UserId),
                        new NpgsqlParameter("ip_experience_data", experienceDataJson) { NpgsqlDbType = NpgsqlTypes.NpgsqlDbType.Jsonb })
                    .FirstOrDefaultAsync();

                if (result != null)
                {
                    upsertExperienceResult.ResultMessage = result.resultmessage;
                    upsertExperienceResult.ResultType = result.resulttype;
                    upsertExperienceResult.UserId = result.userid ?? 0;
                }
                else
                {
                    upsertExperienceResult.ResultMessage = "No result returned from database";
                    upsertExperienceResult.ResultType = 0;
                }
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                upsertExperienceResult.ResultMessage = "Database error: " + ex.Message;
                upsertExperienceResult.ResultType = 0;
            }
            return upsertExperienceResult;
        }

        public async Task<FetchUserProfileResult> GetUserProfileAsync(long userId)
        {
            try
            {
                var profile = await _dbContext.FetchUserProfileAsync(userId);
                if (profile == null || profile.resultmessage.Contains("failed", StringComparison.OrdinalIgnoreCase))
                {
                    return new FetchUserProfileResult
                    {
                        ResultMessage = profile?.resultmessage ?? "Profile fetch failed",
                        ResultType = 0
                    };
                }

                // Map fn_fetch_user_profile to FetchUserProfileResult
                var result = new FetchUserProfileResult
                {
                    ResultMessage = profile.resultmessage ?? "Profile fetch successful",
                    ResultType = 1,
                    ProfileData = new UserProfileData
                    {
                        BasicProfile = profile.resultdata.BasicProfile != null ? new BasicProfileViewModel
                        {
                            FirstName = profile.resultdata.BasicProfile.FirstName,
                            LastName = profile.resultdata.BasicProfile.LastName,
                            Email = profile.resultdata.BasicProfile.Email,
                            PhoneNumber = profile.resultdata.BasicProfile.PhoneNumber,
                            AccountType = profile.resultdata.BasicProfile.AccountType,
                            Gender = profile.resultdata.BasicProfile.Gender,
                            ProfilePic = profile.resultdata.BasicProfile.ProfilePic,
                            Bio = profile.resultdata.BasicProfile.Bio,
                            Location = profile.resultdata.BasicProfile.Location,
                            SocialLink = profile.resultdata.BasicProfile.SocialLink,
                            CreatedOn = profile.resultdata.BasicProfile.CreatedOn,
                            IsActive = profile.resultdata.BasicProfile.IsActive
                        } : null,
                        Jobs = profile.resultdata.Jobs?.Select(j => new JobViewModel
                        {
                            OrganisationId = j.OrganisationId,
                            DesignationId = j.DesignationId,
                            Description = j.Description,
                            Requirement = j.Requirement,
                            Location = j.Location,
                            JobType = j.JobType,
                            JobMode = j.JobMode,
                            Hashtags = j.Hashtags,
                            PayCurrency = j.PayCurrency,
                            PayStartRange = j.PayStartRange,
                            PayEndRange = j.PayEndRange,
                            OpeningDate = j.OpeningDate,
                            ClosingDate = j.ClosingDate,
                            CreatedOn = j.CreatedOn
                        }).ToList(),
                        Courses = profile.resultdata.Courses?.Select(c => new CourseViewModel
                        {
                            CourseName = c.CourseName,
                            CourseType = c.CourseType,
                            Level = c.Level,
                            SubscriptionType = c.SubscriptionType,
                            Status = c.Status,
                            CourseThumbnail = c.CourseThumbnail,
                            CourseBanner = c.CourseBanner,
                            CertificationAvailable = c.CertificationAvailable,
                            Description = c.Description,
                            Cost = c.Cost,
                            PreviewVideoUrl = c.PreviewVideoUrl,
                            CreatedOn = c.CreatedOn,
                            ValidFrom = c.ValidFrom,
                            ValidTo = c.ValidTo
                        }).ToList(),
                        Education = profile.resultdata.Education?.Select(e => new EducationViewModel
                        {
                            EducationLevel = e.EducationLevel,
                            Organisation = e.Organisation,
                            StartDate = e.StartDate,
                            EndDate = e.EndDate
                        }).ToList(),
                        Experience = profile.resultdata.Experience?.Select(e => new ExperienceViewModel
                        {
                            CompanyId = e.CompanyId,
                            DesignationId = e.DesignationId,
                            StartDate = e.StartDate,
                            EndDate = e.EndDate,
                            CurrentlyPursuing = e.CurrentlyPursuing
                        }).ToList(),
                        Posts = profile.resultdata.Posts?.Select(p => new PostViewModel
                        {
                            Content = p.Content,
                            MediaUrl = p.MediaUrl,
                            Hashtags = p.Hashtags,
                            PostVisibility = p.PostVisibility,
                            CreatedOn = p.CreatedOn
                        }).ToList()
                    }
                };

                return result;
            }
            catch (Exception ex)
            {
                _helper.HandleCustomException(ex.Message);
                return new FetchUserProfileResult
                {
                    ResultMessage = "Database error: " + ex.Message,
                    ResultType = 0
                };
            }
        }
    }
}