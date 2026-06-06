IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'hello click me db')
BEGIN
    CREATE DATABASE [hello click me db];
END
GO

USE [hello click me db];
GO

-- Create the Messages table
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Messages')
BEGIN
    CREATE TABLE Messages (
        Id        INT IDENTITY(1,1) PRIMARY KEY,
        Language  NVARCHAR(50)  NOT NULL DEFAULT '',
        Content   NVARCHAR(MAX) NOT NULL DEFAULT ''
    );
END
GO

-- Optional: Insert some sample messages to test
INSERT INTO Messages (Language, Content) VALUES
('en', 'Hello World'),
('en', 'Welcome!'),
('fr', 'Bonjour le monde'),
('fr', 'Bienvenue!'),
('ar', 'مرحبا بالعالم'),
('ar', 'أهلا بك');
GO

SELECT * FROM Messages;
GO