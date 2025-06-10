using System.Globalization;
using System.Runtime.CompilerServices;
using Microsoft.AspNetCore.Mvc;

namespace ProjectIAPI.Controllers{ 

public abstract class BaseController : ControllerBase
{
    private readonly ILogger<BaseController> _logger;

    protected BaseController(ILogger<BaseController> logger)
    {
        _logger = logger;
    }

    protected ActionResult HandleException(Exception ex, [CallerMemberName] string actionName="",[CallerFilePath] string fileName ="" ,[CallerLineNumber] int sourceLineNumber = 0)
    {
        _logger.LogError(ex, ex.Message);

        string LogMainPath = "C:";

         string LogDirectoryFileName = "";
         LogDirectoryFileName = "Log_" + DateTime.Now.ToString("dd-MM-yyyy") + ".txt";

        // string LogFilePath = LogMainPath + "\\ExpatAPILog\\" + DateTime.Now.ToString("yyyy") + "\\" + DateTime.Now.ToString("MMMM", CultureInfo.InvariantCulture)
        //      + "\\" + DateTime.Now.ToString("dd") + "\\" + DateTime.Now.ToString("HH") + "\\";
 
        string LogFilePath = LogMainPath + "\\ProjectIAPI\\" + DateTime.Now.ToString("dd-MM-yyyy")+ "\\";
 
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
             m_logSWriter.WriteLine("Line No:"+sourceLineNumber + ": "+ ex.Message);
             m_logSWriter.Close();
         }
         catch{
              return StatusCode(500, new { ResultMessage = "An internal server error occurred.Unable to write log.", ResultType =0  });
         }

        if (ex is ArgumentNullException)
        {
            return BadRequest(new { ResultMessage = ex.Message, ResultType =0 });
        }
        else if (ex is InvalidOperationException)
        {
            return StatusCode(500, new { ResultMessage = "An internal server error occurred.", ResultType =0  });
        }
        // else if(ex is HttpResponseException)
        // {
        //      return Unauthorized(new { ResultMessage = ex.Message, ResultType =0 });
        // }
        else
        {
            return StatusCode(500, new { ResultMessage = "An unexpected error occurred.", ResultType =0  });
        }
    }
}
}