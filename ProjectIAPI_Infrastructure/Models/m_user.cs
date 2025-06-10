namespace ProjectIAPI_Infrastructure.Models;

public class m_user
{
    public long id { get; set; } = 0;
    public string first_name { get; set; } = string.Empty;
    public string last_name { get; set; } = string.Empty;
    public string phone_number { get; set; } = string.Empty;
    public string email { get; set; } = string.Empty;
    public string password { get; set; } = string.Empty;
    public short account_type { get; set; } = 0; // Changed from user_type to account_type
    public short gender { get; set; } = 0; // Now required
    public string? profile_pic { get; set; } = null;
    public string? bio { get; set; } = null;
    public string? location { get; set; } = null;
    public DateTime created_on { get; set; } = DateTime.UtcNow; // Changed from created_date
    public long created_by { get; set; } = 0; // Now required
    public DateTime updated_on { get; set; } = DateTime.UtcNow; // Changed from updated_date
    public long updated_by { get; set; } = 0; // Now required
    public short login_attempt_count { get; set; } = 0;
    public bool is_active { get; set; } = true;
    public bool is_reset { get; set; } = false;
    public bool is_deleted { get; set; } = false; // New column
    public bool is_sso_user { get; set; } = false; // New column
    public string? social_link { get; set; } = null; // New column
}