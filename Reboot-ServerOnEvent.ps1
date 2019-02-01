#  Original script credit:   https://gallery.technet.microsoft.com/PowerShell-Script-to-Send-873dc0b6
#  Alterations Ian Manning 2018-01-31
#  Monitor for a specific error (Event ID and Message text);  perform a reboot if that event was found since the last run of the task
#  To be run as a scheduledtask - only returns the event log from the last run of the specified task

$global:MachineName="spjntis009.ucles.external"

# This must be set to the name of the scheduled task running the script
$taskname = "eSpecialMonitoredReboot"

$smtpServer = "smtp0"

$emailToYourServiceDesk = "*" # who to alert if the site doesn't come back and needs manual checking
$emailSubjectUsers = "*."
$emailSubjectUsersSiteUp = "****** site back up."
$emailSubjectUsersSiteStillDown = "There has been an unexpected problem encountered in restarting *****"
$emailSubjectYourServiceDeskIgnoreAlerts = "An alert that may have been received is down to a controlled restart ****** web application servers”
$emailSubjectYourServiceSiteStillDown = "There has been an unexpected problem encountered in restarting **********"
$urlToCheck = "https://your.url.com"
$emailFrom = (Get-Content env:computername)+"@domain.suffix"

$eventIDToMonitor = "1234"
$eventMessageToMonitor "Oh no, error!"


    	$EntryType=@("Warning","Error","Information")
		# Only get events since the last run of the task
		$taskinfo=Get-ScheduledTask -TaskName $taskname | Get-ScheduledTaskInfo
		$eventLogs= Get-EventLog -ComputerName $MachineName -LogName Application -EntryType $EntryType -After $taskinfo.LastRunTime
        
        foreach($Event in $eventLogs)    
        {
            if($Event.EventID -eq $eventIDToMonitor -and $Event.Message -eq $eventMessageToMonitor)
            {
				$script:rebootFlag = $true
            }
        }
  If ( $rebootFlag -eq $true ) {
	
	Send-MailMessage -From $emailFrom -To $emailSubjectUsers -Subject $emailSubjectUsers -BodyAsHtml -SmtpServer $smtpServer
	Send-MailMessage -From $emailFrom -To $emailtoYourServiceDesk -Subject $emailSubjectYourServiceDeskIgnoreAlerts -BodyAsHtml -SmtpServer $smtpServer
	shutdown.exe /m \\$MachineName -r
	}
Else {}

Do {
	$webStatus = Invoke-WebRequest -uri $urlToCheck
	Start-Sleep -Seconds 60
	$webStatusCheckCount++
}
Until ( $webStatus.StatusCode -eq 200 -or $webStatusCheckCount -eq 4 )

If ($webStatus.StatusCode -eq 200) {
	Send-MailMessage -From $emailFrom -To $emailSubjectUsers -Subject $emailSubjectUsersSiteUp -BodyAsHtml -SmtpServer $smtpServer
	}
Else {
	Send-MailMessage -From $emailFrom -To $emailSubjectUsers -Subject $emailSubjectUsersSiteStillDown -BodyAsHtml -SmtpServer $smtpServer
	Send-MailMessage -From $emailFrom -To $emailToYourServiceDesk -Subject $emailSubjectYourServiceSiteStillDown -BodyAsHtml -SmtpServer $smtpServer
	}
    
    


