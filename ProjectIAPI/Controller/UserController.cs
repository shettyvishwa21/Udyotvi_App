using Microsoft.AspNetCore.Mvc;
using ProjectIAPI_Core.Interfaces;
using ProjectIAPI_Core.ViewModels;
using Swashbuckle.AspNetCore.Annotations;

namespace ProjectIAPI.Controllers
{
    [Route("api/user")]
    [ApiController]
    public class UserController : BaseController
    {
        private readonly IUserRepository _userRepository;
        private readonly ILogger<UserController> _logger;

        public UserController(IUserRepository userRepository, ILogger<UserController> logger) : base(logger)
        {
            _userRepository = userRepository;
            _logger = logger;
        }

        [Route("register")]
        [HttpPost]
        [SwaggerOperation(Summary = "Register a new user", Description = "Registers a new user with basic information and returns a default password.")]
        [SwaggerResponse(200, "Registration successful", typeof(APIResponse))]
        [SwaggerResponse(400, "Invalid input or registration failed", typeof(APIResponse))]
        [SwaggerResponse(500, "Server error", typeof(APIResponse))]
        public async Task<IActionResult> RegisterUser([FromBody] RegisterRequest request)
        {
            APIResponse _apiResponse = new APIResponse();
            _logger.LogInformation("Registration attempt for user with email: {Email}", request.Email);

            try
            {
                if (!ModelState.IsValid)
                {
                    _apiResponse.ResultMessage = "Invalid inputs";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Model state invalid: {Errors}", ModelState);
                    return BadRequest(_apiResponse);
                }

                var registerResult = await _userRepository.RegisterUser(request);
                _apiResponse.ResultMessage = registerResult.ResultMessage;
                _apiResponse.ResultType = registerResult.ResultType;
                _apiResponse.ResultData = registerResult;

                if (registerResult.ResultType == 0)
                {
                    _logger.LogWarning("Registration failed: {Message}", registerResult.ResultMessage);
                    return BadRequest(_apiResponse);
                }

                _logger.LogInformation("Registration successful for: {Email}", request.Email);
                return Ok(_apiResponse);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for {Email}", request.Email);
                return HandleException(ex);
            }
        }

        [Route("upsert")]
        [HttpPost]
        [SwaggerOperation(Summary = "Inserts or updates a user", Description = "Creates a new user (Id = 0) or updates an existing user (Id > 0).")]
        [SwaggerResponse(200, "User operation successful", typeof(APIResponse))]
        [SwaggerResponse(400, "Invalid input or operation failed", typeof(APIResponse))]
        [SwaggerResponse(500, "Server error", typeof(APIResponse))]
        public async Task<IActionResult> UpsertUser([FromBody] UserUpsert user)
        {
            APIResponse _apiResponse = new APIResponse();
            _logger.LogInformation("Upsert attempt for user with email: {Email}, SSO: {IsSsoUser}", user.Email, user.IsSsoUser);

            try
            {
                if (!ModelState.IsValid)
                {
                    _apiResponse.ResultMessage = "Invalid inputs";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Model state invalid: {Errors}", ModelState);
                    return BadRequest(_apiResponse);
                }

                if (string.IsNullOrEmpty(user.FirstName) || string.IsNullOrEmpty(user.LastName) || string.IsNullOrEmpty(user.Email))
                {
                    _apiResponse.ResultMessage = "First name, last name, and email are required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Required fields missing for: {Email}", user.Email);
                    return BadRequest(_apiResponse);
                }

                if (user.Id == 0 && string.IsNullOrEmpty(user.Password) && !user.IsSsoUser)
                {
                    _apiResponse.ResultMessage = "Password is required for new non-SSO users";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Password missing for new user: {Email}", user.Email);
                    return BadRequest(_apiResponse);
                }

                var upsertResult = await _userRepository.UpsertUser(user);
                if (upsertResult.ResultType == 0 || upsertResult.ResultType == 1) // Success cases
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "User operation successful";
                    _apiResponse.ResultType = 1;
                    _apiResponse.ResultData = upsertResult;
                    _logger.LogInformation("Upsert successful for: {Email}, Result: {Result}", user.Email, upsertResult.ResultMessage);
                }
                else
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "User operation failed";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Upsert failed: {Message}", _apiResponse.ResultMessage);
                    return BadRequest(_apiResponse);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during upsert for {Email}", user.Email);
                return HandleException(ex);
            }
            return Ok(_apiResponse);
        }

        [Route("upsert-education")]
        [HttpPost]
        [SwaggerOperation(Summary = "Inserts or updates education records", Description = "Creates new education records (EducationId = 0) or updates existing ones (EducationId > 0) for a user.")]
        [SwaggerResponse(200, "Education operation successful", typeof(APIResponse))]
        [SwaggerResponse(400, "Invalid input or operation failed", typeof(APIResponse))]
        [SwaggerResponse(500, "Server error", typeof(APIResponse))]
        public async Task<IActionResult> UpsertEducation([FromBody] EducationUpsert education)
        {
            APIResponse _apiResponse = new APIResponse();
            _logger.LogInformation("Upsert education attempt for user ID: {UserId}", education.UserId);

            try
            {
                if (!ModelState.IsValid)
                {
                    _apiResponse.ResultMessage = "Invalid inputs";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Model state invalid for user ID: {UserId}", education.UserId);
                    return BadRequest(_apiResponse);
                }

                if (education.UserId <= 0)
                {
                    _apiResponse.ResultMessage = "Valid user ID is required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Invalid user ID: {UserId}", education.UserId);
                    return BadRequest(_apiResponse);
                }

                if (education.EducationData == null || !education.EducationData.Any())
                {
                    _apiResponse.ResultMessage = "Education data is required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Education data missing for user ID: {UserId}", education.UserId);
                    return BadRequest(_apiResponse);
                }

                var upsertResult = await _userRepository.UpsertEducation(education);
                if (upsertResult.ResultType == 0 || upsertResult.ResultType == 1)
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "Education operation successful";
                    _apiResponse.ResultType = 1;
                    _apiResponse.ResultData = upsertResult;
                    _logger.LogInformation("Education upsert successful for user ID: {UserId}, Result: {Result}", education.UserId, upsertResult.ResultMessage);
                }
                else
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "Education operation failed";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Education upsert failed for user ID: {UserId}, Message: {Message}", education.UserId, upsertResult.ResultMessage);
                    return BadRequest(_apiResponse);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during education upsert for user ID: {UserId}", education.UserId);
                return HandleException(ex);
            }
            return Ok(_apiResponse);
        }

        [Route("upsert-experience")]
        [HttpPost]
        [SwaggerOperation(Summary = "Inserts or updates experience records", Description = "Creates new experience records (experience_id = 0) or updates existing ones (experience_id > 0) for a user.")]
        [SwaggerResponse(200, "Experience operation successful", typeof(APIResponse))]
        [SwaggerResponse(400, "Invalid input or operation failed", typeof(APIResponse))]
        [SwaggerResponse(500, "Server error", typeof(APIResponse))]
        public async Task<IActionResult> UpsertExperience([FromBody] ExperienceUpsert experience)
        {
            APIResponse _apiResponse = new APIResponse();
            _logger.LogInformation("Upsert experience attempt for user ID: {UserId}", experience.UserId);

            try
            {
                if (!ModelState.IsValid)
                {
                    _apiResponse.ResultMessage = "Invalid inputs";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Model state invalid for user ID: {UserId}", experience.UserId);
                    return BadRequest(_apiResponse);
                }

                if (experience.UserId <= 0)
                {
                    _apiResponse.ResultMessage = "Valid user ID is required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Invalid user ID: {UserId}", experience.UserId);
                    return BadRequest(_apiResponse);
                }

                if (experience.ExperienceData == null || !experience.ExperienceData.Any())
                {
                    _apiResponse.ResultMessage = "Experience data is required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Experience data missing for user ID: {UserId}", experience.UserId);
                    return BadRequest(_apiResponse);
                }

                var upsertResult = await _userRepository.UpsertExperience(experience);
                if (upsertResult.ResultType == 0 || upsertResult.ResultType == 1)
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "Experience operation successful";
                    _apiResponse.ResultType = 1;
                    _apiResponse.ResultData = upsertResult;
                    _logger.LogInformation("Experience upsert successful for user ID: {UserId}, Result: {Result}", experience.UserId, upsertResult.ResultMessage);
                }
                else
                {
                    _apiResponse.ResultMessage = upsertResult.ResultMessage ?? "Experience operation failed";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Experience upsert failed for user ID: {UserId}, Message: {Message}", experience.UserId, upsertResult.ResultMessage);
                    return BadRequest(_apiResponse);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during experience upsert for user ID: {UserId}", experience.UserId);
                return HandleException(ex);
            }
            return Ok(_apiResponse);
        }

        [Route("{userId}")]
        [HttpGet]
        [SwaggerOperation(Summary = "Fetches a user profile", Description = "Retrieves the profile data (basic profile, jobs, courses, education, experience, posts) for a specified user ID.")]
        [SwaggerResponse(200, "Profile fetch successful", typeof(APIResponse))]
        [SwaggerResponse(404, "Profile not found or fetch failed", typeof(APIResponse))]
        [SwaggerResponse(400, "Invalid user ID", typeof(APIResponse))]
        [SwaggerResponse(500, "Server error", typeof(APIResponse))]
        public async Task<IActionResult> GetUserProfile(long userId)
        {
            APIResponse _apiResponse = new APIResponse();
            _logger.LogInformation("Fetch profile attempt for user ID: {UserId}", userId);

            try
            {
                if (userId <= 0)
                {
                    _apiResponse.ResultMessage = "Valid user ID is required";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Invalid user ID: {UserId}", userId);
                    return BadRequest(_apiResponse);
                }

                var profileResult = await _userRepository.GetUserProfileAsync(userId);
                if (profileResult == null || profileResult.ResultMessage.Contains("failed", StringComparison.OrdinalIgnoreCase))
                {
                    _apiResponse.ResultMessage = profileResult?.ResultMessage ?? "Profile not found";
                    _apiResponse.ResultType = 0;
                    _logger.LogWarning("Profile fetch failed for user ID: {UserId}, Message: {Message}", userId, _apiResponse.ResultMessage);
                    return NotFound(_apiResponse);
                }

                _apiResponse.ResultMessage = profileResult.ResultMessage ?? "Profile fetch successful";
                _apiResponse.ResultType = 1;
                _apiResponse.ResultData = profileResult;
                _logger.LogInformation("Profile fetch successful for user ID: {UserId}", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during profile fetch for user ID: {UserId}", userId);
                return HandleException(ex);
            }
            return Ok(_apiResponse);
        }
    }
}