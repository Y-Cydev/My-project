using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class HelloClickMeController : ControllerBase
{
    private readonly MyDbContext _db;

    public HelloClickMeController(MyDbContext db) => _db = db;

    [HttpGet]
    public string Get()
    {
        var lang = Request.Headers["Accept-Language"].ToString();
        var msgs = _db.Messages.Where(m => m.Language == lang).ToArray();
        if (msgs.Length == 0) return "No message yet!";
        var index = new Random().Next(0, msgs.Length);
        return msgs[index]?.Content ?? "Message not found";
    }

    [HttpGet("all")]
    public async Task<ActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 10, [FromQuery] string? search = null)
    {
        var query = _db.Messages.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(m => m.Content.Contains(search));

        var total = await query.CountAsync();
        var messages = await query
            .OrderBy(m => m.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new { data = messages, total, page, pageSize });
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
        var msg = new Message { Content = dto.Content, Language = dto.Language };
        _db.Messages.Add(msg);
        _db.SaveChanges();
        return Ok(new { message = "Message created successfully", id = msg.Id });
    }

    [HttpPut("{id}")]
    public ActionResult Update(int id, [FromBody] MessageDto dto)
    {
        var msg = _db.Messages.Find(id);
        if (msg == null) return NotFound(new { message = "Message not found" });
        msg.Content = dto.Content;
        msg.Language = dto.Language;
        _db.SaveChanges();
        return Ok(new { message = "Message updated successfully" });
    }

    [HttpDelete("{id}")]
    public ActionResult Delete(int id)
    {
        var msg = _db.Messages.Find(id);
        if (msg == null) return NotFound(new { message = "Message not found" });
        _db.Messages.Remove(msg);
        _db.SaveChanges();
        return Ok(new { message = "Message deleted successfully" });
    }

    [HttpPost("delete-batch")]
    public ActionResult DeleteBatch([FromBody] List<int> ids)
    {
        if (ids == null || ids.Count == 0)
            return BadRequest(new { message = "No IDs provided" });

        var messages = _db.Messages.Where(m => ids.Contains(m.Id)).ToList();
        if (messages.Count == 0)
            return NotFound(new { message = "No messages found" });

        _db.Messages.RemoveRange(messages);
        _db.SaveChanges();
        return Ok(new { message = $"{messages.Count} message(s) deleted" });
    }
}

public class MessageDto
{
    public string Content { get; set; } = "";
    public string Language { get; set; } = "";
}