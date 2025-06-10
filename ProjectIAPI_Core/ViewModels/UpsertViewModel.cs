using System.ComponentModel.DataAnnotations;

namespace ProjectIAPI_Core.ViewModels
{
    /// <summary>
    /// Represents the data required to insert or update a user in the system.
    /// </summary>
    public class UserUpsert
    {
        /// <summary>
        /// The ID of the user. Use 0 for insert, or a positive value for update.
        /// </summary>
        public long Id { get; set; } = 0;

        /// <summary>
        /// The first name of the user. Required field.
        /// </summary>
        [Required(ErrorMessage = "First name is required")]
        public string? FirstName { get; set; } = string.Empty;

        /// <summary>
        /// The last name of the user. Required field.
        /// </summary>
        [Required(ErrorMessage = "Last name is required")]
        public string? LastName { get; set; } = string.Empty;

        /// <summary>
        /// The phone number of the user. Optional field.
        /// </summary>
        public string? PhoneNumber { get; set; } = string.Empty;

        /// <summary>
        /// The email address of the user. Required field.
        /// </summary>
        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string? Email { get; set; } = string.Empty;

        /// <summary>
        /// The password for the user account. Optional for updates.
        /// </summary>
        public string? Password { get; set; } = string.Empty;

        /// <summary>
        /// The type of user account (e.g., 1 for regular user).
        /// </summary>
        public int UserType { get; set; } = 0;

        /// <summary>
        /// The gender of the user (e.g., 1 for male, 2 for female).
        /// </summary>
        public int Gender { get; set; } = 0;

        /// <summary>
        /// The URL or path to the user's profile picture. Optional field.
        /// </summary>
        public string? ProfilePic { get; set; } = string.Empty;

        /// <summary>
        /// A brief bio or description of the user. Optional field.
        /// </summary>
        public string? Bio { get; set; } = string.Empty;

        /// <summary>
        /// The location of the user. Optional field.
        /// </summary>
        public string? Location { get; set; } = string.Empty;

        /// <summary>
        /// The ID of the user who created or is updating this record.
        /// </summary>
        public long CreatedBy { get; set; } = 0;

        /// <summary>
        /// Indicates whether the user account is active.
        /// </summary>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// Indicates whether the user account is marked as deleted.
        /// </summary>
        public bool IsDeleted { get; set; } = false;

        /// <summary>
        /// Indicates whether the user account uses SSO login.
        /// </summary>
        public bool IsSsoUser { get; set; } = false;

        /// <summary>
        /// The URL to the user's social media profile. Optional field.
        /// </summary>
        public string? SocialLink { get; set; } = string.Empty;
    }

    /// <summary>
    /// Represents the result of an upsert operation on a user.
    /// </summary>
    public class UpsertUserResult
    {
        /// <summary>
        /// The result type of the operation (e.g., 0 for insert success, 1 for update success).
        /// </summary>
        public int ResultType { get; set; } = 0;

        /// <summary>
        /// The message describing the result of the operation.
        /// </summary>
        public string? ResultMessage { get; set; } = string.Empty;

        /// <summary>
        /// The ID of the user affected by the operation.
        /// </summary>
        public long UserId { get; set; } = 0;
    }
}