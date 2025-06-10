namespace ProjectIAPI_Core.ViewModels;

public class UserProfileResponse
{
    public string ResultMessage { get; set; } = string.Empty;
    public List<object> ResultData { get; set; } = new List<object>();
}

public class BasicProfile
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string AccountType { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public string ProfilePic { get; set; } = string.Empty;
    public string Bio { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string SocialLink { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public bool IsActive { get; set; }
}

public class Job
{
    public int OrganisationId { get; set; }
    public int DesignationId { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Requirement { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public int JobType { get; set; }
    public int JobMode { get; set; }
    public string Hashtags { get; set; } = string.Empty;
    public int PayCurrency { get; set; }
    public decimal PayStartRange { get; set; }
    public decimal PayEndRange { get; set; }
    public DateTime OpeningDate { get; set; }
    public DateTime ClosingDate { get; set; }
    public DateTime CreatedOn { get; set; }
}

public class Course
{
    public string CourseName { get; set; } = string.Empty;
    public string CourseType { get; set; } = string.Empty;
    public string Level { get; set; } = string.Empty;
    public string SubscriptionType { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CourseThumbnail { get; set; } = string.Empty;
    public string CourseBanner { get; set; } = string.Empty;
    public bool CertificationAvailable { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Cost { get; set; }
    public string PreviewVideoUrl { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime ValidTo { get; set; }
}

public class Education
{
    public string EducationLevel { get; set; } = string.Empty;
    public string Organisation { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
}

public class Experience
{
    public int CompanyId { get; set; }
    public int DesignationId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool CurrentlyPursuing { get; set; }
}

public class Post
{
    public string Content { get; set; } = string.Empty;
    public string MediaUrl { get; set; } = string.Empty;
    public string Hashtags { get; set; } = string.Empty;
    public string PostVisibility { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}