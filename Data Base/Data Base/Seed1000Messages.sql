USE [hello click me db];
GO

DECLARE @i INT = 1;

WHILE @i <= 1000
BEGIN
    DECLARE @lang NVARCHAR(2) = CASE ABS(CHECKSUM(NEWID())) % 3
        WHEN 0 THEN 'en'
        WHEN 1 THEN 'fr'
        ELSE 'ar'
    END;

    DECLARE @phrase NVARCHAR(100) = CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Hello World'
        WHEN 1 THEN 'Good morning'
        WHEN 2 THEN 'How are you'
        WHEN 3 THEN 'Welcome'
        WHEN 4 THEN 'Nice to meet you'
        WHEN 5 THEN 'Good evening'
        WHEN 6 THEN 'See you later'
        WHEN 7 THEN 'Have a nice day'
        WHEN 8 THEN 'Take care'
        ELSE 'Best regards'
    END;

    IF @lang = 'fr'
        SET @phrase = CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'Bonjour le monde'
            WHEN 1 THEN 'Bon matin'
            WHEN 2 THEN 'Comment allez-vous'
            WHEN 3 THEN 'Bienvenue'
            WHEN 4 THEN 'Enchanté'
            WHEN 5 THEN 'Bonsoir'
            WHEN 6 THEN 'À plus tard'
            WHEN 7 THEN 'Bonne journée'
            WHEN 8 THEN 'Prenez soin'
            ELSE 'Meilleures salutations'
        END;

    IF @lang = 'ar'
        SET @phrase = CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'مرحبا بالعالم'
            WHEN 1 THEN 'صباح الخير'
            WHEN 2 THEN 'كيف حالك'
            WHEN 3 THEN 'أهلا وسهلا'
            WHEN 4 THEN 'تشرفنا'
            WHEN 5 THEN 'مساء الخير'
            WHEN 6 THEN 'إلى اللقاء'
            WHEN 7 THEN 'يوم سعيد'
            WHEN 8 THEN 'اعتني بنفسك'
            ELSE 'أطيب التحيات'
        END;

    INSERT INTO Messages (Language, Content) VALUES (@lang, @phrase + ' - ' + CAST(@i AS NVARCHAR));

    SET @i = @i + 1;
END;
GO

SELECT COUNT(*) AS TotalMessages FROM Messages;
GO
