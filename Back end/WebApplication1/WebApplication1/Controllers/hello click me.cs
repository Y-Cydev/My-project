using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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
        return GetRandomMessage(lang);
    }

    [HttpGet("all")]
    public ActionResult GetAll()
    {
        var messages = _db.Messages.ToList();
        return Ok(messages);
    }

    [HttpGet("random")]
    public ActionResult GetRandom()
    {
        var msgs = _db.Messages.ToArray();
        if (msgs.Length == 0)
            return Ok(new { content = "No messages yet!", language = "" });

        var index = new Random().Next(0, msgs.Length);
        return Ok(msgs[index]);
    }

    [HttpPost]
    public ActionResult Create([FromBody] MessageDto dto)
    {
        var msg = new Message
        {
            Content = dto.Content,
            Language = dto.Language
        };
        _db.Messages.Add(msg);
        _db.SaveChanges();
        return Ok(new { message = "Message created successfully", id = msg.Id });
    }

    [HttpPut]
    public ActionResult Update([FromBody] UpdateDto dto)
    {
        var msg = _db.Messages.FirstOrDefault(m =>
            m.Content == dto.OriginalContent && m.Language == dto.Language);

        if (msg == null)
            return NotFound(new { message = "Message not found" });

        msg.Content = dto.NewContent;
        _db.SaveChanges();
        return Ok(new { message = "Message updated successfully" });
    }

    [HttpDelete]
    public ActionResult Delete([FromQuery] string content, [FromQuery] string language)
    {
        var msg = _db.Messages.FirstOrDefault(m =>
            m.Content == content && m.Language == language);

        if (msg == null)
            return NotFound(new { message = "Message not found" });

        _db.Messages.Remove(msg);
        _db.SaveChanges();
        return Ok(new { message = "Message deleted successfully" });
    }

    private string GetRandomMessage(string lang)
    {
        var msgs = _db.Messages.Where(m => m.Language == lang).ToArray();
        if (msgs.Length == 0) return "not message yet!";
        var index = new Random().Next(0, msgs.Length);
        return msgs[index]?.Content ?? "Message not found";
    }
}

public class MessageDto
{
    public string Content { get; set; } = "";
    public string Language { get; set; } = "";
}

public class UpdateDto
{
    public string OriginalContent { get; set; } = "";
    public string NewContent { get; set; } = "";
    public string Language { get; set; } = "";
}