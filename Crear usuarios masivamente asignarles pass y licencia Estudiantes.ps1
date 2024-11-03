# Ruta del archivo CSV
$csvPath = "C:\Users\usuario\Desktop\TEAMS\usuarios_prueba.csv" # Reemplazar por la ruta a tu archivo
$usuarios = Import-Csv -Path $csvPath

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

    # Imprimir las variables para verificar sus valores
    Write-Host "Verificando los valores para el usuario:"
    Write-Host "UserPrincipalName: $userPrincipalName"
    Write-Host "DisplayName: $displayName"
    Write-Host "MailNickname: $mailNickname"
    Write-Host "Password: $password"
    Write-Host "GivenName: $givenName"
    Write-Host "Surname: $surname"
    Write-Host "UsageLocation: $usageLocation"
    Write-Host "SkuId: $skuId"
    Write-Host ""

    # Crear el usuario
    try {
        New-MgUser -UserPrincipalName $userPrincipalName `
                    -DisplayName $displayName `
                    -MailNickname $mailNickname `
                    -AccountEnabled `
                    -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $false } `
                    -GivenName $givenName `
                    -Surname $surname `
                    -UsageLocation $usageLocation

        # Asignar la licencia al usuario recién creado usando UserPrincipalName
        try {
            Set-MgUserLicense -UserId $userPrincipalName -AddLicenses @{SkuId = $skuId} -RemoveLicenses @()
            Write-Host "Usuario $displayName creado y licencia asignada correctamente."
        } catch {
            Write-Host "Error al asignar licencia a ${displayName}: $($_.Exception.Message)"
        }
        
    } catch {
        Write-Host "Error al crear el usuario ${displayName}: $($_.Exception.Message)"
    }
}
