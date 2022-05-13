Function Send-Report {
    $Message = "This is the Admin Users Report generated on $(Get-Date).<br> This report was sent from this server: $env:COMPUTERNAME"
    $Title = "Admin User Reports $(Get-Date)"
    $Post = "<P>Thank You, <br>Systems Administrator</P>"

    $MessageParameters = @{
        Subject = "Admin User Reports $(Get-Date)"
        Body = ConvertTo-Html -Title $Title -Body $Message -Post $Post | Out-String
        From = "SysAdmin@domain.com"
        To = "User.Name@domain.com"
        SmtpServer = "smtp.domain.com"
        Attachments = (Get-ChildItem -Path "C:\$env:COMPUTERNAME-AdminGroups-*.csv" -File).FullName
    }

    Send-MailMessage @MessageParameters -BodyAsHtml
}

$Domains = "domain.com","domain.local"

$Groups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Server Operators",
    "vCenter-Admins"
)

foreach ($Domain in $Domains) {
    foreach ($Group in $Groups) {
        try {
            $ADGroup = Get-ADGroup -Server $Domain -Identity $Group -Properties * -ErrorAction Stop
            $GroupMembers = $ADGroup | Get-ADGroupMember -Recursive | Where-Object objectclass -eq 'user'

            foreach ($Member in $GroupMembers) {
                $User = $Member | Get-ADUser -Properties *

                $Props = @{
                    'GroupDomain'=($ADGroup.CanonicalName).Split("/")[0]
                    'GroupName'=$ADGroup.Name
                    'UserDomain'=($User.CanonicalName).Split("/")[0]
                    'UserAccountName'=$User.samAccountName
                    'UserOULocation'=$User.CanonicalName
                    'IsEnabled'=$User.Enabled
                }

                $UserObject = New-Object -TypeName PSObject -Property $Props
            }

            $UserObject | Select-Object -Property GroupDomain,GroupName,UserDomain,UserAccountName,UserOULocation,IsEnabled | Export-Csv -Path "C:\$env:COMPUTERNAME-AdminGroups-$(Get-Date -f yyyy-MM-dd).csv" -Append -NoTypeInformation
        } catch {
            Start-Sleep -Seconds 1
        }
    }
}

Send-Report
Start-Sleep -Seconds 5
Remove-Item -Path  "C:\$env:COMPUTERNAME-AdminGroups-$(Get-Date -f yyyy-MM-dd).csv" -Force