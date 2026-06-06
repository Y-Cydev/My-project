using Microsoft.EntityFrameworkCore;

public class MyDbContext : DbContext
{
    public MyDbContext(DbContextOptions<MyDbContext> options) : base(options) { }

    public DbSet<Message> Messages { get; set; }
}

public class Message
{
    public int Id { get; set; }
    public string Language { get; set; } = "";
    public string Content { get; set; } = "";
}