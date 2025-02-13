$fonts = @{
    "Poppins-Regular" = "https://fonts.gstatic.com/s/poppins/v22/pxiEyp8kv8JHgFVrJJfedw.ttf"
    "Poppins-Medium" = "https://fonts.gstatic.com/s/poppins/v22/pxiByp8kv8JHgFVrLGT9Z1xlEA.ttf"
    "Poppins-SemiBold" = "https://fonts.gstatic.com/s/poppins/v22/pxiByp8kv8JHgFVrLEj6Z1xlEA.ttf"
    "Poppins-Bold" = "https://fonts.gstatic.com/s/poppins/v22/pxiByp8kv8JHgFVrLCz7Z1xlEA.ttf"
}

# Créer le dossier fonts s'il n'existe pas
New-Item -ItemType Directory -Force -Path "assets/fonts"

# Télécharger chaque police
foreach ($font in $fonts.GetEnumerator()) {
    $outputPath = "assets/fonts/$($font.Key).ttf"
    Write-Host "Téléchargement de $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile $outputPath
    Write-Host "Téléchargé dans $outputPath"
}
