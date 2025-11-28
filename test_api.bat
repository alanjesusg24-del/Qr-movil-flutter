@echo off
echo Testing API Endpoint: /businesses/nearby
echo.
echo URL: https://gerald-ironical-contradictorily.ngrok-free.dev/api/v1/businesses/nearby
echo Parameters: latitude=19.432847^&longitude=-99.133208^&radius=10^&limit=20
echo.

curl -X GET "https://gerald-ironical-contradictorily.ngrok-free.dev/api/v1/businesses/nearby?latitude=19.432847&longitude=-99.133208&radius=10&limit=20" ^
  -H "Content-Type: application/json" ^
  -H "Accept: application/json" ^
  -H "ngrok-skip-browser-warning: true" ^
  -v

echo.
echo.
pause
