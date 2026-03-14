<#
.SYNOPSIS
    Automatiza la gestion de usuarios en Active Directory mediante archivos CSV.

.DESCRIPTION
    Este script procesa un archivo CSV para realizar altas de nuevos usuarios y actualizaciones de cuentas existentes. 
    Realiza una validacion previa de la Unidad Organizativa (OU), sanea los nombres de usuario y gestiona atributos 
    como el puesto, departamento y telefono. Requiere el modulo de Active Directory instalado.

.PARAMETER RutaCSV
    Define la ubicacion del archivo de origen con los datos de los empleados.

.EXAMPLE
    .\Provision-Users.ps1
    Ejecuta el proceso utilizando las rutas configuradas por defecto en el script.

.NOTES
    Autor: Axier Banez - @AxierSysOp
    Version: 1.1
    Licencia: MIT (Uso libre y abierto).
    Aviso: Este script se proporciona "tal cual". Realiza cambios masivos en AD.
    Se recomienda probar en entornos de laboratorio antes de su uso en produccion.
#>

# --- Inicializacion y avisos ---
Clear-Host
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "      PROVISIONAMIENTO DE CUENTAS - ACTIVE DIRECTORY       " -ForegroundColor White
Write-Host "       Desarrollado por: Axier Banez  (@AxierSysOp)        " -ForegroundColor Gray
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "AVISO: Use este script bajo su propia responsabilidad." -ForegroundColor Yellow
Write-Host "Se recomienda una verificacion previa del archivo CSV." -ForegroundColor Yellow
Write-Host ""

# --- Configuracion de entorno ---
$RutaCSV   = "C:\Temp\user-data-sample.csv"  
$RutaOU    = "OU=Staging,OU=employees,OU=Corporate,DC=corp,DC=contoso,DC=com" 
$SufijoUPN = "contoso.com"

# Solicitud segura de contrasena
Write-Host "--- Paso previo: Solicitud de contrasena temporal para las cuentas ---" -ForegroundColor Yellow
$Password = Read-Host "Introduce la contrasena temporal para las nuevas cuentas" -AsSecureString

if (-not $Password) {
    Write-Host "[Error] La contrasena no puede estar vacia." -ForegroundColor Red
    return
}

# Importacion del modulo de Active Directory
if (-not (Get-Module -ListAvailable ActiveDirectory)) {
    Write-Error "El modulo de Active Directory no esta instalado en este sistema."
    return
}
Import-Module ActiveDirectory

# --- 1. Verificacion preventiva de la infraestructura ---
Write-Host "1. Verificando existencia de la OU: $RutaOU" -NoNewline -ForegroundColor Cyan
try {
    $CheckOU = Get-ADOrganizationalUnit -Identity $RutaOU -ErrorAction Stop
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    Write-Host " [Critico]" -ForegroundColor Red
    Write-Host "--------------------------------------------------------" -ForegroundColor Red
    Write-Host "La ruta de la OU es incorrecta. Revisa Active Directory." -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------" -ForegroundColor Red
    return 
}
Write-Host ""

# --- 2. Importacion del archivo CSV ---
if (Test-Path $RutaCSV) {
    $Usuarios = Import-Csv $RutaCSV -Delimiter ";" -Encoding UTF8
} else {
    Write-Host " [Error] Archivo CSV no encontrado en: $RutaCSV" -ForegroundColor Red
    return
}

Write-Host "2. Procesando $($Usuarios.Count) registros..." -ForegroundColor Cyan
Write-Host ""

# --- 3. Bucle de gestion de usuarios ---
Write-Host "3. Iniciando el procesamiento de cuentas..." -ForegroundColor Cyan

foreach ($Fila in $Usuarios) {
    
    # Omitimos registros sin identificador unico
    if ([string]::IsNullOrWhiteSpace($Fila.usuario)) { continue }
    
    # Saneamiento de datos basicos
    $SamAccountName = $Fila.usuario.ToLower().Trim()
    $Nombre         = if ($Fila.Nombre)    { $Fila.Nombre.Trim() }    else { "" }
    $Apellidos      = if ($Fila.Apellidos) { $Fila.Apellidos.Trim() } else { "" }
    
    $DisplayName    = "$Nombre $Apellidos".Trim()
    $UserPrincipal  = "$SamAccountName@$SufijoUPN"
    
    # Logica para la descripcion segun el tipo de acceso
    $InfoAcceso = @()
    if ($Fila.local -match "X|x")  { $InfoAcceso += "Local" }
    if ($Fila.remoto -match "X|x") { $InfoAcceso += "Remoto" }
    $Description = "Acceso: " + ($InfoAcceso -join " / ")

    # 4. Definicion de parametros mediante Splatting
    $DatosDetalle = @{
        GivenName    = $Nombre
        Surname      = $Apellidos
        DisplayName  = $DisplayName
        Description  = $Description
        EmailAddress = if ($Fila.CORREO) { $Fila.CORREO.Trim().ToLower() } else { "" }
    }
    
    # Adicion de campos adicionales dinamicos
    if ($Fila.PROVINCIA)    { $DatosDetalle.Add("State", $Fila.PROVINCIA.Trim()) }
    if ($Fila.DEPARTAMENTO) { $DatosDetalle.Add("Department", $Fila.DEPARTAMENTO.Trim()) }
    if ($Fila.PUESTO)       { $DatosDetalle.Add("Title", $Fila.PUESTO.Trim()) }
    if ($Fila.Telefono_T)   { $DatosDetalle.Add("OfficePhone", $Fila.Telefono_T.Trim()) }

    # 5. Logica de Upsert (actualizar si existe / crear si es nuevo)
    $ADUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'"
    
    if ($ADUser) {
        Write-Host " - [Actualizar ficha] $SamAccountName" -ForegroundColor Yellow
        try {
            Set-ADUser -Identity $SamAccountName @DatosDetalle -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo actualizar $SamAccountName : $($_.Exception.Message)"
        }
    } else {
        Write-Host " - [Nueva alta] $SamAccountName..." -NoNewline -ForegroundColor Green
        try {
            New-ADUser -SamAccountName $SamAccountName `
                       -UserPrincipalName $UserPrincipal `
                       -Name $DisplayName `
                       -AccountPassword $Password `
                       -Path $RutaOU `
                       -Enabled $true `
                       -ChangePasswordAtLogon $true `
                       -ErrorAction Stop
            
            # Aplicamos el resto de datos de la ficha
            Set-ADUser -Identity $SamAccountName @DatosDetalle -ErrorAction Stop
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " [Error] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- Proceso finalizado con exito ---" -ForegroundColor Cyan