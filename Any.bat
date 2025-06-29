@echo off
REM Desativa a exibição de comandos no terminal

REM Caminho da pasta a ser excluída
set folderPath=C:\Users\atila\AppData\Roaming\AnyDesk

REM Verifica se a pasta existe
if exist "%folderPath%" (
    echo Excluindo a pasta: %folderPath%
    rmdir /s /q "%folderPath%"
) else (
    echo A pasta %folderPath% não existe.
)

echo Operação concluída.