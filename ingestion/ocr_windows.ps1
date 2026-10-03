# OCR de imágenes PNG con el motor OCR de Windows (Windows.Media.Ocr, idioma es-ES).
# Uso: powershell.exe -NoProfile -File ingestion/ocr_windows.ps1 <lista.txt>
#   lista.txt: una línea por imagen "<ruta_png>`t<ruta_json_salida>".
# Escribe, por imagen, un JSON con las líneas y las palabras con su caja (x, y, w, h en píxeles).
# Lo usa ingestion/diputados_inmuebles.py (solo funciona en Windows 10/11 con el paquete de idioma español).
param([string]$Lista)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, [Type]$tipo) {
    $t = $asTaskGeneric.MakeGenericMethod($tipo).Invoke($null, @($op))
    $t.Wait(-1) | Out-Null
    $t.Result
}

$lang = New-Object Windows.Globalization.Language 'es-ES'
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
if ($null -eq $engine) { Write-Error 'No hay motor OCR es-ES'; exit 2 }

foreach ($linea in [System.IO.File]::ReadAllLines($Lista)) {
    if (-not $linea.Trim()) { continue }
    $partes = $linea.Split("`t")
    $png = $partes[0]; $salida = $partes[1]
    try {
        $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($png)) ([Windows.Storage.StorageFile])
        $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $res = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
        $lineas = @()
        foreach ($l in $res.Lines) {
            $pal = @()
            foreach ($w in $l.Words) {
                $r = $w.BoundingRect
                $pal += @{ t = $w.Text; x = [int]$r.X; y = [int]$r.Y; w = [int]$r.Width; h = [int]$r.Height }
            }
            $lineas += @{ t = $l.Text; w = $pal }
        }
        $obj = @{ ancho = $bitmap.PixelWidth; alto = $bitmap.PixelHeight; lineas = $lineas }
        [System.IO.File]::WriteAllText($salida, ($obj | ConvertTo-Json -Depth 6 -Compress), [System.Text.Encoding]::UTF8)
        $stream.Dispose(); $bitmap.Dispose()
    } catch {
        Write-Output "ERROR $png $_"
    }
}
