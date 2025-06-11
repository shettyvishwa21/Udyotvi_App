using System.Security.Cryptography;
using System.Text;
using System.Net.Mail;
using System.Net;
using ProjectIAPI_Core.ViewModels;
using System.Runtime.CompilerServices;

namespace ProjectIAPI_Infrastructure.Helper
{
public class CommonHelper
{
    public CommonHelper()
    {
        
    }
    //#region  Uniq ID
    // public string Get8DigitsUniqueId()
    //         {
    //             var bytes = new byte[4];
    //             var rng = RandomNumberGenerator.Create();
    //             rng.GetBytes(bytes);
    //             uint random = BitConverter.ToUInt32(bytes, 0) % 100000000;
    //             return String.Format("{0:D8}", random);
    //         }

    // #endregion
    #region  Encrypt Password
    public string EncryptPassword(string passwordStr)
    {
        string returnEncrypetdPassword = "";
            
            using (SHA256 crypt = SHA256.Create())
            {

            System.Text.StringBuilder hash = new System.Text.StringBuilder();
            byte[] crypto = crypt.ComputeHash(Encoding.UTF8.GetBytes(passwordStr), 0, Encoding.UTF8.GetByteCount(passwordStr));
            foreach (byte theByte in crypto)
            {
                hash.Append(theByte.ToString("x2"));
            }
            returnEncrypetdPassword = hash.ToString();
            }
            return returnEncrypetdPassword;
    }

    #endregion  

    #region To GenerateRandom Password
     public string GenerateRandomPassword()
        {
            string characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            Random random = new Random();

            string password = new string(Enumerable.Repeat(characters, 8)
                .Select(s => s[random.Next(s.Length)]).ToArray());

            return password;
        }
    #endregion

    #region  Handle Custom Exception
    public void HandleCustomException(string message="", [CallerMemberName] string actionName="",[CallerFilePath] string fileName ="" ,[CallerLineNumber] int sourceLineNumber = 0)
    {
        string LogMainPath = "C:";

         string LogDirectoryFileName = "";
         LogDirectoryFileName = "Log_" + DateTime.Now.ToString("dd-MM-yyyy") + ".txt";

         string LogFilePath = LogMainPath + "\\ExpatAPILog\\" + DateTime.Now.ToString("dd-MM-yyyy")+ "\\";

        DirectoryInfo dirInfo = new DirectoryInfo(LogFilePath);
        if (!dirInfo.Exists)
        {         
          Directory.CreateDirectory(LogFilePath);
        }

         try
         {
             StreamWriter m_logSWriter = null;
             m_logSWriter = new StreamWriter(LogFilePath + LogDirectoryFileName, true);
             m_logSWriter.WriteLine(DateTime.Now.ToString("HH:mm:ss:ffff : ") +  fileName + ":"+ actionName + "()");
             m_logSWriter.WriteLine("Line No:"+sourceLineNumber + ": "+ message);
             m_logSWriter.Close();
         }
         catch{
              throw new Exception(message);
         }
         //var customErrorMessage = "Error occured.Please try again. If the issue persists, contact our support team for assistance";
        
    }

    #endregion  


   
}
}