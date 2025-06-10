using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ProjectIAPI_Core.ViewModels
{
    public class FetchUserProfileResult
    {
        public string ResultMessage { get; set; }
        public int ResultType { get; set; }
        public UserProfileData ProfileData { get; set; }
    }
 
    public class UserProfileData
    {
        public BasicProfileViewModel BasicProfile { get; set; }
        public List<JobViewModel> Jobs { get; set; }
        public List<CourseViewModel> Courses { get; set; }
        public List<EducationViewModel> Education { get; set; }
        public List<ExperienceViewModel> Experience { get; set; }
        public List<PostViewModel> Posts { get; set; }
    }

    public class BasicProfileViewModel
    {
        [Required]
        public string FirstName { get; set; }
        [Required]
        public string LastName { get; set; }
        [Required]
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public string AccountType { get; set; }
        public string Gender { get; set; }
        public string ProfilePic { get; set; }
        public string Bio { get; set; }
        public string Location { get; set; }
        public string SocialLink { get; set; }
        [Required]
        public DateTime CreatedOn { get; set; }
        [Required]
        public bool IsActive { get; set; }
    }

    public class JobViewModel
{
    public int OrganisationId { get; set; }
    public int DesignationId { get; set; }
    public string Description { get; set; }
    public string Requirement { get; set; }
    public string Location { get; set; }
    public string JobType { get; set; }
    public string JobMode { get; set; }
    public string[] Hashtags { get; set; }
    public string PayCurrency { get; set; }
    public decimal PayStartRange { get; set; }
    public decimal PayEndRange { get; set; }
    public DateTime OpeningDate { get; set; }
    public DateTime ClosingDate { get; set; }
    public DateTime CreatedOn { get; set; }
}

    public class CourseViewModel
    {
        [Required]
        public string CourseName { get; set; }
        [Required]
        public string CourseType { get; set; }
        [Required]
        public string Level { get; set; }
        public string SubscriptionType { get; set; }
        public string Status { get; set; }
        public string CourseThumbnail { get; set; }
        public string CourseBanner { get; set; }
        [Required]
        public bool CertificationAvailable { get; set; }
        public string Description { get; set; }
        public decimal Cost { get; set; }
        public string PreviewVideoUrl { get; set; }
        [Required]
        public DateTime CreatedOn { get; set; }
        [Required]
        public DateTime ValidFrom { get; set; }
        [Required]
        public DateTime ValidTo { get; set; }
    }

    public class EducationViewModel
    {
        [Required]
        public string EducationLevel { get; set; }
        [Required]
        public string Organisation { get; set; }
        [Required]
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; } // Changed to nullable and removed [Required]
    }

    public class ExperienceViewModel
    {
        [Required]
        public int CompanyId { get; set; }
        [Required]
        public int DesignationId { get; set; }
        [Required]
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; } // Changed to nullable and removed [Required]
        [Required]
        public bool CurrentlyPursuing { get; set; }
    }

    public class PostViewModel
    {
        [Required]
        public string Content { get; set; }
        public string MediaUrl { get; set; }
        public string[] Hashtags { get; set; }
        [Required]
        public string PostVisibility { get; set; }
        [Required]
        public DateTime CreatedOn { get; set; }
    }
}