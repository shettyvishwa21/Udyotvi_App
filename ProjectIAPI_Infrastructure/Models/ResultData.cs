namespace ProjectIAPI.Infrastructure.Models
{
    // Class to represent the overall structure of resultdata
    public class ResultData
    {
        public BasicProfile BasicProfile { get; set; }
        public List<Job> Jobs { get; set; }
        public List<Course> Courses { get; set; }
        public List<Education> Education { get; set; }
        public List<Experience> Experience { get; set; }
        public List<Post> Posts { get; set; }
    }

    // Class to represent the basic_profile object
    public class BasicProfile
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public string AccountType { get; set; }
        public string Gender { get; set; }
        public string ProfilePic { get; set; }
        public string Bio { get; set; }
        public string Location { get; set; }
        public string SocialLink { get; set; }
        public DateTime CreatedOn { get; set; }
        public bool IsActive { get; set; }
    }

    // Class to represent a Job
    public class Job
    {
        public long OrganisationId { get; set; }
        public long DesignationId { get; set; }
        public string Description { get; set; }
        public string Requirement { get; set; }
        public string Location { get; set; }
        public string JobType { get; set; }
        public string JobMode { get; set; }
        public string Hashtags { get; set; }
        public string PayCurrency { get; set; }
        public decimal PayStartRange { get; set; }
        public decimal PayEndRange { get; set; }
        public DateTime OpeningDate { get; set; }
        public DateTime ClosingDate { get; set; }
        public DateTime CreatedOn { get; set; }
    }

    // Class to represent a Course
    public class Course
    {
        public string CourseName { get; set; }
        public string CourseType { get; set; }
        public string Level { get; set; }
        public string SubscriptionType { get; set; }
        public string Status { get; set; }
        public string CourseThumbnail { get; set; }
        public string CourseBanner { get; set; }
        public bool CertificationAvailable { get; set; }
        public string Description { get; set; }
        public decimal Cost { get; set; }
        public string PreviewVideoUrl { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime ValidFrom { get; set; }
        public DateTime ValidTo { get; set; }
    }

    // Class to represent Education
    public class Education
    {
        public string EducationLevel { get; set; }
        public string Organisation { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; } // Nullable because it might not have an end date
    }

    // Class to represent Experience
    public class Experience
    {
        public long CompanyId { get; set; }
        public long DesignationId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; } // Nullable because it might not have an end date
        public bool CurrentlyPursuing { get; set; }
    }

    // Class to represent a Post
    public class Post
    {
        public string Content { get; set; }
        public string MediaUrl { get; set; }
        public string Hashtags { get; set; }
        public string PostVisibility { get; set; }
        public DateTime CreatedOn { get; set; }
    }
}