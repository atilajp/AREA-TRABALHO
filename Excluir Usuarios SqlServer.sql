-- ===========================================
-- Remover usuário e login de TODO o servidor
-- ===========================================
DECLARE @LoginName SYSNAME = N'mixfiscal';  -- << ALTERE AQUI >>
DECLARE @SQL NVARCHAR(MAX);

PRINT '🔍 Verificando login "' + @LoginName + '"...';

---------------------------------------------------------------
-- 1️⃣ Verifica se o login existe no servidor
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @LoginName)
BEGIN
    PRINT '⚠️ Login não encontrado no servidor.';
    RETURN;
END

---------------------------------------------------------------
-- 2️⃣ Para cada banco de dados, remover o usuário associado
---------------------------------------------------------------
DECLARE @DBName SYSNAME;

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE'
  AND database_id > 4  -- ignora master, tempdb, model, msdb
ORDER BY name;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '---------------------------------------------';
    PRINT '🧹 Limpando o banco: ' + @DBName;

    SET @SQL = N'
    USE [' + @DBName + '];
    DECLARE @UserName SYSNAME = (SELECT name FROM sys.database_principals WHERE sid = SUSER_SID(''' + @LoginName + '''));

    IF @UserName IS NOT NULL
    BEGIN
        PRINT ''   Removendo usuário '' + @UserName;

        -- 🔹 1. Remove de roles
        DECLARE @Role NVARCHAR(255), @cmd NVARCHAR(MAX);
        DECLARE role_cursor CURSOR FOR
        SELECT dp2.name
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp1 ON drm.member_principal_id = dp1.principal_id
        JOIN sys.database_principals dp2 ON drm.role_principal_id = dp2.principal_id
        WHERE dp1.name = @UserName;
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @Role;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @cmd = ''EXEC sp_droprolemember @rolename = N'''''' + @Role + '''''', @membername = N'''''' + @UserName + '''''';'';
            EXEC(@cmd);
            FETCH NEXT FROM role_cursor INTO @Role;
        END
        CLOSE role_cursor;
        DEALLOCATE role_cursor;

        -- 🔹 2. Transferir propriedade de schemas
        DECLARE @Schema SYSNAME;
        DECLARE schema_cursor CURSOR FOR
        SELECT name FROM sys.schemas WHERE principal_id = USER_ID(@UserName);
        OPEN schema_cursor;
        FETCH NEXT FROM schema_cursor INTO @Schema;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC(''ALTER AUTHORIZATION ON SCHEMA::['' + @Schema + ''] TO dbo'');
            FETCH NEXT FROM schema_cursor INTO @Schema;
        END
        CLOSE schema_cursor;
        DEALLOCATE schema_cursor;

        -- 🔹 3. Revogar permissões e remover usuário
        EXEC(''REVOKE CONNECT TO ['' + @UserName + '']'');
        EXEC(''DROP USER ['' + @UserName + '']'');
    END
    ';
    
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

---------------------------------------------------------------
-- 3️⃣ Finalmente, remover o login do servidor
---------------------------------------------------------------
PRINT '---------------------------------------------';
PRINT '🗑️ Removendo login do servidor...';

BEGIN TRY
    EXEC('DROP LOGIN [' + @LoginName + ']');
    PRINT '✅ Login excluído com sucesso.';
END TRY
BEGIN CATCH
    PRINT '❌ Erro ao excluir login: ' + ERROR_MESSAGE();
END CATCH;
