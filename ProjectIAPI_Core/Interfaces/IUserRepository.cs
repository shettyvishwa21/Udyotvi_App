using ProjectIAPI_Core.ViewModels;

namespace ProjectIAPI_Core.Interfaces
{
    public interface IUserRepository
    {
        Task<RegisterResult> RegisterUser(RegisterRequest request);
        Task<UpsertUserResult> UpsertUser(UserUpsert user);
        Task<UpsertEducationResult> UpsertEducation(EducationUpsert education);
        Task<UpsertExperienceResult> UpsertExperience(ExperienceUpsert experience);
        Task<FetchUserProfileResult> GetUserProfileAsync(long userId);
    }
}