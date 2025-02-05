# Columnas del archivo mailNickname;displayName;userPrincipalName;password;firstname;lastname;usageLocation;skuId
# Ruta del archivo CSV
$csvPath = "C:\Users\usuario\Desktop\MATRICULACION\PowerShell\usuarioserror.csv" # Reemplazar por la ruta a tu archivo
$logErrorPath = "C:\Users\usuario\Desktop\MATRICULACION\PowerShell\log_errores.txt"
$logSuccessPath = "C:\Users\usuario\Desktop\MATRICULACION\PowerShell\log_exitos.txt"

# Limpiar logs anteriores
if (Test-Path $logErrorPath) { Remove-Item $logErrorPath }
if (Test-Path $logSuccessPath) { Remove-Item $logSuccessPath }

$usuarios = Import-Csv -Path $csvPath -Delimiter ";"

# Crear usuarios y asignarles licencias
foreach ($usuario in $usuarios) {
    # Definir las variables
    $userPrincipalName = $usuario.UserPrincipalName
    $displayName = $usuario.DisplayName
    $mailNickname = $usuario.MailNickname
    $password = $usuario.Password
    $givenName = $usuario.GivenName
    $surname = $usuario.Surname
    $usageLocation = $usuario.UsageLocation
    $skuId = $usuario.SkuId  # SKU desde el CSV

    # Verificar valores antes de continuar
    Write-Host "Verificando los valores para el usuario: $userPrincipalName"
    Write-Host "DisplayName: $displayName"
    Write-Host "MailNickname: $mailNickname"
    Write-Host "UsageLocation: $usageLocation"
    Write-Host "SkuId: $skuId"
    Write-Host ""

    # Validar displayName antes de continuar
    if (-not $displayName -or $displayName -eq "") {
        $errorMessage = "Error: displayName no puede estar vacío para $userPrincipalName."
        Write-Host $errorMessage
        Add-Content -Path $logErrorPath -Value $errorMessage
        continue  # Saltar este usuario
    }

    # Asegurar que displayName no exceda 256 caracteres
    $displayName = $displayName.Substring(0, [Math]::Min($displayName.Length, 256))

    # Crear el usuario
    try {
        New-MgUser -UserPrincipalName $userPrincipalName `
                   -DisplayName $displayName `
                   -MailNickname $mailNickname `
                   -AccountEnabled `
                   -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $false } `
                   -UsageLocation $usageLocation

        Write-Host "Usuario $displayName creado correctamente."
        Add-Content -Path $logSuccessPath -Value "Usuario creado: $userPrincipalName - $displayName"

        # Validar el SkuId antes de asignar la licencia
        if ($skuId -match "^[0-9a-fA-F-]+$") {
            try {
                Set-MgUserLicense -UserId $userPrincipalName -AddLicenses @{SkuId = $skuId} -RemoveLicenses @()
                Write-Host "Licencia asignada correctamente a $displayName."
                Add-Content -Path $logSuccessPath -Value "Licencia asignada a: $userPrincipalName - $skuId"
            } catch {
                $errorMessage = "Error al asignar licencia a ${displayName}: $($_.Exception.Message)"
                Write-Host $errorMessage
                Add-Content -Path $logErrorPath -Value $errorMessage
            }
        } else {
            $warningMessage = "Advertencia: SkuId inválido para $displayName. No se asignó licencia."
            Write-Host $warningMessage
            Add-Content -Path $logErrorPath -Value $warningMessage
        }

    } catch {
        $errorMessage = "Error al crear el usuario ${displayName}: $($_.Exception.Message)"
        Write-Host $errorMessage
        Add-Content -Path $logErrorPath -Value $errorMessage
    }
}

Write-Host "Proceso finalizado. Revisa los archivos de log:"
Write-Host "Errores: $logErrorPath"
Write-Host "Éxitos: $logSuccessPath"
