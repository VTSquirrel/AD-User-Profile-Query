param(
    [Parameter(Mandatory=$true)][string[]]$Targets
)

Clear-Host

$Result = New-Object System.Collections.Generic.List[System.Object]
$LineBreak = "---------------------------------------------"

#Change to the names of the properties to display
$Properties = @("DisplayName", "EmailAddress", "OfficePhone", "Title", "Department")



Write-Host "[INFO] Running on " -ForegroundColor Gray -NoNewline
Write-Host $Targets.Length -ForegroundColor Cyan -NoNewline
Write-Host " devices." -ForegroundColor Gray

foreach ($Target in $Targets){
    $Target = $Target.ToUpper()
    Write-Host $LineBreak
    Write-Host "Running on $Target"

    #Attempt to estabnlish PSSession to the target device. If it fails, skip to the next in the list
    try{
        $TargetSession = New-PSSession -ComputerName $Target -ErrorAction Stop
    }catch{
        Write-Host "Unable to establish remote session" -ForegroundColor Red
        Continue
    }

    Write-Host "`tFetching user profiles... " -NoNewline -ForegroundColor Gray
    #Fetch the user profiles
    $UserProfiles = Invoke-Command -Session $TargetSession -ScriptBlock{
        Get-CimInstance -ClassName Win32_UserProfile |
        Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru | Select UserName -ExpandProperty UserName -ErrorAction SilentlyContinue
    }
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "`tQuerying Active Directory... " -NoNewline -ForegroundColor Gray
    #Loop through returned profiles
    $hasADError = $false
    foreach ($profile in $UserProfiles){
        #Split the string to get domain and profile name
        $parts = $profile.Split("\")

        #Ignore anything that is not a domain user (ex: local accounts)
        if (($parts[0] -ne "NT AUTHORITY") -and ($parts[0] -ne $Target)){
            
            $ProfileName = $parts[1]

            try{
                #Connect to AD to select the properties defined above for this profile
                $ADUser = Get-ADUser -Identity $ProfileName -Properties * | Select $Properties -ErrorAction Continue

                #Append the computer name
                $AD2 = $ADUser | Select @{N="ComputerName";E={$Target}}, *

                #Add to results list
                $Result.add($AD2)
            }catch{
                $hasADError = $true
                Write-Host "`n`t`tUnable to retrieve Active Directory profile information for $ProfileName" -ForegroundColor Red
            }
        }
    }
    if (-not($hasADError)){
        Write-Host "Complete" -ForegroundColor Green
    }else{
        Write-Host "`tComplete" -ForegroundColor Green
    }
    
    #Remove the PSSession for this device
    Remove-PSSession $TargetSession
}
Write-Host $LineBreak
Write-Host "Done." -ForegroundColor Green
$Result | ft -a