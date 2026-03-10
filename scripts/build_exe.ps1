param(
    [string]$Python = "python"
)

& $Python -m pip install -r requirements.txt
& $Python -m PyInstaller --noconfirm --onefile --name ZoomMate --icon zoommate.ico --add-data "images;images" --add-data "Includes;Includes" app.py
