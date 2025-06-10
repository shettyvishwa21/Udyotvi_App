namespace ProjectIAPI_Core.ViewModels
{
    public class ChangePasswordRequest
    {
        public long UserId { get; set; }
        public string CurrentPassword { get; set; }
        public string NewPassword { get; set; }
    }

    public class ChangePasswordResult
    {
        public string ResultMessage { get; set; }
        public int ResultType { get; set; } // 0 for failure, 1 for success
    }
}