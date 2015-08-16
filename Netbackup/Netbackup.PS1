<#
Мониторинг web-интерфейса Netbackup
Скрипт проверяет доступность web-интерфейса Netbackup при помощи post-запроса.
Проверяет, есть ли висящие алерты.
В итоге шлет письмо. 
Письмо придет прочитанным, либо непрочитанным с ошибкой в опеределенную папку (нужно настроить правило в Outlook).
Запускается через задание в планировщике.
#>

#Как обойти https
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$link = "https://link:port/opscenter/monitor.overview.do"
$link2 = "https://link:port/opscenter/loadLogin.do?userName=NAMEOFUSER&password=PASSWORDOFUSER&domain=DOMAINOFUSER%28vx%29&save=Log+On"

#Делаем get-запрос по линку. Сохраняем сессию в переменной fb.
$session = Invoke-WebRequest $link2 -SessionVariable sess_save

$re = Invoke-WebRequest -Uri $link -WebSession $sess_save -Method Post -Body $form.Fields

#Проверим, что на странице отображается текст
$t_1 = $re.Content -match "Job Summary by State"

#Вычислим endtime, оно каждый раз меняется
$endtime = $re.Content.Split(" ") -match "applyFilter=15&timeLineType" -split("&") -match "endTime" -replace "\D+"

#В Alert Summary все должно быть по нулям
$t_2 = $re.Content -match ('applyFilter=15&timeLineType=TIME_RANGE_CUSTOM&startTime=1&endTime=' + $endtime + '&ViewIdFilter=-100" tabindex="0"><font class="TextBlue">0</font></a>')
$t_3 = $re.Content -match ('applyFilter=16&timeLineType=TIME_RANGE_CUSTOM&startTime=1&endTime=' + $endtime + '&ViewIdFilter=-100" tabindex="0"><font class="TextBlue">0</font></a>')
$t_4 = $re.Content -match ('applyFilter=17&timeLineType=TIME_RANGE_CUSTOM&startTime=1&endTime=' + $endtime + '&ViewIdFilter=-100" tabindex="0"><font class="TextBlue">0</font></a>')
$t_5 = $re.Content -match ('applyFilter=18&timeLineType=TIME_RANGE_CUSTOM&startTime=1&endTime=' + $endtime + '&ViewIdFilter=-100" tabindex="0"><font class="TextBlue">0</font></a>')

if ($t_1 -And $t_2 -And $t_3 -And $t_4 -And $t_5)
{
    $Subject = "Норма при проверке пречека: NetBackup"
    $text5 = "Все в норме"
}
else
{
    $Subject = "Ошибка при проверке пречека: NetBackup"
    $text5 = "`n Проверить по ссылке: https://link:port/opscenter/monitor.overview.do"
}

#Отправим письмо
$EmailFrom = “EmailFrom@.ru”
$EmailTo = “EmailTo@.ru”

$body = $text5

$Encoding = [System.Text.Encoding]::UTF8 
 $SmtpServer = “ip_of_SmtpServer”
 [string]$Encoding="utf-8"
 $messageParameters = @{                        
		Encoding = [System.Text.Encoding]::GetEncoding($Encoding)
            } 

 Send-MailMessage @messageParameters -From $EmailFrom -To $EmailTo -SmtpServer $SmtpServer -Body $body -Subject $Subject 

 