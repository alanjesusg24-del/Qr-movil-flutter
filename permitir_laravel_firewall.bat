@echo off
echo Creando regla de firewall para Laravel Server (puerto 8000)...
netsh advfirewall firewall add rule name="Laravel Development Server" dir=in action=allow protocol=TCP localport=8000
echo.
echo Regla creada exitosamente!
echo Ahora puedes acceder al servidor desde tu celular en: http://192.168.1.66:8000
pause
