<#
В связи с выпуском новой версии Citrix Xenapp 7.6 и Receiver 4.x перестал работать pagent, при помощи которого можно было делать logoff из всех сессий данного пользователя
Данный скрипт удаленно запускает на одной из виртуалок Citrix командлет и выполняет logoff
Ниже представлены различные способы logoff для версий Xenapp 6.5 и выше, а также для версии Xenapp 5
#>

$client_sess65 = New-PSSession -ComputerName vm_65

Invoke-Command -session $client_sess65 {Add-PSSnapin Citrix*}

Invoke-Command -session $client_sess65 {Get-XASession | Select-Object -Property SessionID,AccountName,ServerName,State  | Where-Object { $_.AccountName -eq 'domain\username'} | Stop-XASession}

Remove-PSSession $client_sess65


#Для версии Xenapp 5
$client_sess50 = New-PSSession -ComputerName vm_50

Invoke-Command -session $client_sess50 {$farm = new-Object -com “MetaframeCOM.MetaframeFarm”}

Invoke-Command -session $client_sess50 {$farm.Initialize(1)}

$stop50 = Invoke-Command -session $client_sess50 {$farm.Sessions | Where-Object {$_.UserName -eq "username"} | foreach {$_.Logoff($_.SessionID)}}

Remove-PSSession $client_sess50



