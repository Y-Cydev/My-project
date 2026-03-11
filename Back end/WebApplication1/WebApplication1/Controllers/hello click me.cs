using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class HelloClickMeController : ControllerBase
{
    [HttpGet]
    public string Get()
    {
        var lang = Request.Headers["Accept-Language"].ToString();

        if (lang.StartsWith("ar"))
        {
            return Message("ar");
        }
        else if (lang.StartsWith("fr"))
        {
            return Message("fr");
        }
        else
        {
            return Message("en");
        }
    }

    public static string Message(string lng)
    {
        throw new NotImplementedException();


        //fetch message in database base on lng
        //EntityFreamwork core
    }
}
