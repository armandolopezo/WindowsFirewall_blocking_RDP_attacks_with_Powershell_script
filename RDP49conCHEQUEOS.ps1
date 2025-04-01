# RDC Brute Force Prevention 
# .
# .

# Copy firewall log file
Copy-Item -LiteralPath C:\Windows\System32\LogFiles\Firewall\pfirewall.log -Destination C:\Windows\System32\LogFiles\Firewall\pfirewall-source.log

#ALO 1 - insertado 26-1-2024
Copy-Item -LiteralPath C:\Windows\System32\LogFiles\Firewall\pfirewall.log -Destination C:\Windows\System32\LogFiles\Firewall\pfirewall-ALO.log
#ALO 1 - insertado 26-1-2024

# Declare variables
$FirewallLog = 'C:\Windows\System32\LogFiles\Firewall\pfirewall-source.log'
$FirewallRule = Get-NetFirewallRule -DisplayName "RDC Brute Force Prevention"
$CSVHeader = 'Date', 'Time', 'Action', 'Protocol', 'SourceIP', 'DestIP', 'SourcePort', 'DestPort'
$CSVFile = Import-Csv -Delimiter ' ' -Path $FirewallLog -Header $CSVHeader

#ALO 4 - insertado 27-1-2024
write-host " ************** Se muestra archivo CSV importado  si se quita comentario de linea 21 (linea siguiente del script) *********************"
write-host " "
### $CSVFile
write-host " "
write-host " **********************************************************************************************************"
Start-Sleep 2 
#ALO 4 - insertado 27-1-2024

$Date = Get-Date -DisplayHint Date -Format "yyyy-MM-dd"
$Time = Get-Date -DisplayHint Time -Format "HH:mm:ss"
$TimeSub5 = (Get-Date -DisplayHint Time).AddMinutes(-5)
$TimeSub600 = (Get-Date -DisplayHint Time).AddMinutes(-600)
$TimeSub600
$Obj = New-Object PSObject
$Subnets = @()
$NewScope = @()
$ExistingScope = @()
# Add firewall rule (if it doesn't already exist)
If ($FirewallRule -EQ $null) {
    # Firewall rule does not exist
    New-NetFirewallRule -DisplayName "RDC Brute Force Prevention" -Direction Inbound -Action Block -RemoteAddress '255.255.255.254'
} else {
    # Do nothing; firewall rule exists
    
    # ALO 7 - insertado 27-1-2024
    Write-Host "********************************************************************"
    write-host "ALO - regla de firewall llamada RDC Brute Force Prevention ya existe"
    Write-Host "********************************************************************"
    # ALO 7 - insertado 27-1-2024
}

# Clear existing subnets from firewall rule after 24 hours
If ($Time -LIKE "00:00:**") {
    # It's midnight
    Write-Host "************* ALO - Es Medianoche **************************"
    Set-NetFirewallRule -DisplayName "RDC Brute Force Prevention" -RemoteAddress '255.255.255.254'
} else {
    # Do nothing
     Write-Host "************* ALO - NO es Medianoche **************************"
}

# Import CSV | Skip the first 5 lines | Criteria: 
## - Date is today
## - Time is between the last 5 minutes and now
## - Source IP is not the host
## - Destination port is 3389
## - Count the number of IPs trying to connect to 3389 in the last 5 minutes
$CSVFile | Select -Skip 5 | Where {$_.Date -EQ $Date -and $_.Time -GE $TimeSub600.ToString("HH:mm:ss") -and $_.SourceIP -NE '127.0.0.1' -and $_.DestPort -EQ '3389'} | Group-Object -Property SourceIP -NoElement | Where {$_.Count -GT '10'} | Sort-Object -Descending | % {
    # Convert counted IPs to subnets and add to $Subnets array
    ForEach-Object {
        $IPAddress = "$($_.Name)".ToString()
        
        #ALO 6 - insertado 27-1-2024
         Write-Host "************* ALO - a continuacion se muestra IPADDRESS **************************"
         $IPAddress
         Start-Sleep 1
         Write-Host "**********************************************************************************"
        #ALO 6 - insertado 27-1-2024
        
        $Byte = $IPAddress.Split(".")
        $Subnet = ($Byte[0] + "." + $Byte[1] + "." + $Byte[2] + "." + $Byte[3] + "/255.255.255.255")
        
        #ALO 5 - insertado 27-1-2024
         Write-Host "************* ALO - a continuacion subnet de un ForEach **************************"
         $Subnet
         Start-Sleep 1
         Write-Host "**********************************************************************************"
        #ALO 5 - insertado 27-1-2024
        
        $Subnets += $Subnet
        }
    }

# Remove duplicate subnets from Subnets array
$Subnets = ($Subnets | Sort -Unique)
write-host "*********************************************************************************"
write-host "linea siguiente muestra arreglo SUBNETS"
$Subnets
# $Subnets.GetType()
# write-host "******** Los siguientes son los elementos del arreglo SUBNETS"
# $Subnets[0]
# $Subnets[1]
# $Subnets[2]
# $Subnets[3]
# $Subnets[4]
# $Subnets[5]

# write-host "*********************************************************************************"

# Add new subnets to NewScope array
 $ExistingScope = (Get-NetFirewallRule -DisplayName  RDC Brute Force Prevention  | Get-NetFirewallAddressFilter).RemoteAddress
 #  $ExistingScope
 # write-host "*********************************************************************************"
# write-host "linea siguiente muestra EXISTINGSCOPE 3 veces antes de agregar subnets"
# $ExistingScope=$ExistingScope + ' '
# $ExistingScope
# $ExistingScope
# $ExistingScope
# $ExistingScope.GetType()  - EL tipo de la variable EXISTINGSCOPE es STRING (creo)
# write-host "*********************************************************************************"
 
 if ($ExistingScope -ne  255.255.255.254 )  {$ExistingScope = @()
                                            $ExistingScope += $Subnets
} else {
    $ExistingScope = @()
    $ExistingScope += $Subnets
}

# write-host "*********************************************************************************"
# write-host "linea siguiente muestra EXISTINGSCOPE una vez DESPUES de agregar subnets"
# $Existingscope
# write-host "*********************************************************************************"
 

# Remove duplicate subnets from NewScope array
 $NewScope = ($ExistingScope | Sort -Unique)
 write-host "****** linea siguiente muestra newSCOPE UNA VEZ"
 $NewScope

# write-host "*********************************************************************************"
# write-host "linea siguiente muestra newSCOPE 2 veces"
#  $NewScope
# $NewScope
# write-host "*********************************************************************************"

# alo - La siguiente linea muestra Remote Addresses de FIREWALL RULE RDC Brute Force Prevention  ANTES de NUEVA CONFIGURACION
write-host  "La siguiente linea muestra Remote Addresses de FIREWALL RULE RDC Brute Force Prevention  ANTES de NUEVA CONFIGURACION"
get-NetFirewallRule -DisplayName "RDC Brute Force Prevention" | Get-NetFirewallAddressFilter| select -ExpandProperty RemoteAddress

if ($NewScope -ne  255.255.255.254 )  {
# Add new subnets to firewall rule
Set-NetFirewallRule -DisplayName "RDC Brute Force Prevention" -RemoteAddress $NewScope
# alo - La siguiente linea muestra Remote Addresses de FIREWALL RULE RDC Brute Force Prevention  DESPUES de nueva CONFIGURACION
write-host "La siguiente linea muestra Remote Addresses de FIREWALL RULE RDC Brute Force Prevention  DESPUES de nueva CONFIGURACION"
get-NetFirewallRule -DisplayName "RDC Brute Force Prevention" | Get-NetFirewallAddressFilter | select -ExpandProperty RemoteAddress
}
# Write to event log
New-EventLog -LogName Application -Source "RDC Brute Force Prevention Script" -ErrorAction SilentlyContinue
Write-EventLog -LogName Application -Source "RDC Brute Force Prevention Script" -EntryType Information -EventId 1 -Message "The following subnets have been blocked for 24 hours:`n$NewScope"

# Remove old source firewall log files

#ALO 2 - insertado 26-1-2024
Copy-Item -LiteralPath C:\Windows\System32\LogFiles\Firewall\pfirewall.log -Destination C:\Windows\System32\LogFiles\Firewall\pfirewall-sourceALO.log
#ALO 2 - insertado 26-1-2024

Remove-Item -Force C:\Windows\System32\LogFiles\Firewall\pfirewall-source.log 

#ALO 3 - insertado 26-1-2024
start-sleep 2
#ALO 3 - insertado 26-1-2024