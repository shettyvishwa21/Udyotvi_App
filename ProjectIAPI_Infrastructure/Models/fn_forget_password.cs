namespace ProjectIAPI_Infrastructure
{
    public class fn_forget_password
    {
        public string result_message { get; set; } = string.Empty;
        public int result_type { get; set; } = 0;
        public string temp_password { get; set; } = string.Empty;
        public long user_id { get; set; } = 0;
    }


}
