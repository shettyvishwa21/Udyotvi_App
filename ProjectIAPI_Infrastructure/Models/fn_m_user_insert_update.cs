namespace ProjectIAPI_Infrastructure.Models
{
    /// <summary>
    /// Represents the result of the fn_m_user_insert_update PostgreSQL function.
    /// </summary>
    public class fn_m_user_insert_update
    {
        /// <summary>
        /// The result type of the operation (e.g., 0 for insert success, 1 for update success, or error codes).
        /// </summary>
        public int resulttype { get; set; }

        /// <summary>
        /// The message describing the result of the operation.
        /// </summary>
        public string resultmessage { get; set; } = string.Empty;

        /// <summary>
        /// The ID of the user affected by the operation, nullable to handle error cases where no ID is returned.
        /// </summary>
        public long? userid { get; set; } = 0;
    }
}