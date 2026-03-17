using Microsoft.AspNetCore.Mvc;
using System.Linq;

[ApiController]
[Route("api/[controller]")]
public class HelloClickMeController : ControllerBase
{
    private readonly MyDbContext _db;

    public HelloClickMeController(MyDbContext db)
    {
        _db = db;
    }

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

    private string Message(string lng)
    {
        var msg = _db.Messages.FirstOrDefault(m => m.Language == lng);

        if (msg != null)
        {
            return msg.Content;
        }
        else
        {
            return "Message not found";
        }
    }
}