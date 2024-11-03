# Ruta al archivo CSV
$csvPath = "C:\Users\54358\Desktop\TEAMS\equipos_limpios.csv"

# Importa los datos del archivo CSV
$teams = Import-Csv -Path $csvPath -Delimiter ';'

# Recorre cada equipo en el archivo CSV
foreach ($team in $teams) {
    try {
        if ([string]::IsNullOrWhiteSpace($team.displayName)) {
            Write-Host "displayName inválido para: '$($team.displayName)'"
            continue
        }

        $baseMailNickname = $team.displayName.Trim().Replace(" ", "").ToLower()
        $mailNickname = "${baseMailNickname}1"

        # Reiniciar el sufijo para cada equipo
        $mailNicknameSuffix = 1

        $existingGroup = Get-MgGroup -Filter "mailNickname eq '$mailNickname'" -ErrorAction SilentlyContinue
        while ($existingGroup) {
            $mailNicknameSuffix++
            $mailNickname = "${baseMailNickname}${mailNicknameSuffix}"
            $existingGroup = Get-MgGroup -Filter "mailNickname eq '$mailNickname'" -ErrorAction SilentlyContinue
        }

        $newGroup = New-MgGroup -DisplayName $team.displayName.Trim() -MailEnabled `
                    -MailNickname $mailNickname -GroupTypes @("Unified") `
                    -Description "Equipo de clase" -SecurityEnabled 

        if ($newGroup -ne $null) {
            $teamProperties = @{
                displayName          = $team.displayName.Trim()
                mailNickname         = $mailNickname
                "template@odata.bind" = "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')"
                groupId              = $newGroup.Id
            }

            # Crea el equipo sin 'visibility'
            New-MgTeam -BodyParameter $teamProperties
            Write-Host "Equipo creado exitosamente: $($team.displayName)"
        } else {
            Write-Host "Error al crear el grupo para: $($team.displayName)"
        }
    } catch {
        Write-Host "Error al crear el equipo para $($team.displayName): $($_.Exception.Message)"
    }
}



Disconnect-MgGraph