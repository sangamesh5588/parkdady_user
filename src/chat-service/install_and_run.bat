@echo off
echo Installing Parking Chat Service dependencies...
echo.

pip install -r requirements.txt

if %errorlevel% neq 0 (
    echo.
    echo Error installing dependencies. Please check your Python installation.
    pause
    exit /b 1
)

echo.
echo Downloading NLTK data...
python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords')"

if %errorlevel% neq 0 (
    echo.
    echo Error downloading NLTK data.
    pause
    exit /b 1
)

echo.
echo Starting the chat service on http://localhost:8000
echo Press Ctrl+C to stop the service
echo.

python app.py
