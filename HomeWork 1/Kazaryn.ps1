﻿#########################################################################################################
##	Описание
##	Автор: Талипов А.Г 
##	Верися 0.8
##
##	Скрипт выполняет загрузку файлов с сайта brokenstone.ru
##	В качестве входных параметров необходимо перадить логи и пароль от сайта и путь для сохранения файлов.
##
#########################################################################################################
[CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("DownloadFolder")] 
        [string]$OutFolder="\\avtostrada.biz\Екатеринбург\Общая корзина\Ж.Д. База\brokstone\"  
 
      <#  [Parameter(Mandatory=$false)] 
        [string]$Login='Avtostrada', 
         
        [Parameter(Mandatory=$false)]
        [string]$Password="5ed8f5"#>
     )
        

$h1 = @{
Host= 'brokenstone.ru'
'User-Agent'= 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
Accept= 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'    
'Accept-Language'= 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4'
'Accept-Encoding'= 'gzip, deflate, sdch'
}

switch ($Env:COMPUTERNAME) {
    'gatzilla' { $downloadFolder ="G:\Temp\brokstone\"; break }
    'k001'     { $downloadFolder ="c:\usr\"; break }

    Default {$downloadFolder=$OutFolder}
}

#$logfile=$downloadFolder + "logs\script.log"

function ChekFolders ($folder=$downloadFolder) {
    
    if (!(Test-Path $folder)) {

        $NewFolder = New-Item $folder -Force -ItemType Directory 
        $newFolderLog = New-Item ($folder + "logs") -Force -ItemType Directory 
        $newFolderMounth = New-Item ($folder + "за месяц") -Force -ItemType Directory
        Write-Log -Message "Созданы папки"
               
    }


}


function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path=$downloadFolder + "logs\script.log", 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'SilentlyContinue' 
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Создан $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}
# данная функция определяет папку для сохранения файла в зввисимости от названия ссылки
function outFolder ($Link, $downloadFolder) {

				switch -regex ($Link) {
											
									"Январь"    {$outFolder=$downloadFolder + "за Месяц\"; break}
									"Февраль"   {$outFolder=$downloadFolder + "за Месяц\"; break}
									"Март"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Апрель"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Май"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Июнь"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Июль"		{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Август"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Сентябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Октябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Ноябрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									"Декабрь"	{$outFolder=$downloadFolder + "за Месяц\"; break}
									Default 	{$outFolder=$downloadFolder}
									}

		return $outFolder
}
#Данная функция выдает массив объектами которые сожержат очишенные ссылки названия и ид файлов а так же пути для сохранения. 
function getURL ($links,$downloadFolder){
	$URLS1 = @()
	$OldUrlsTemp =@()
	if ((Test-Path ($downloadFolder + "logs\downloadurls.xml")) -eq $true) {
	$OldUrls1 = Import-Clixml ($downloadFolder + "logs\downloadurls.xml")
	}
	else { Write-log "файла  downloadurls.xml нет"}
					
		foreach ($download in ($links | Where-Object {$_.href -like "*Downloading.aspx?file*"})) {
			
			$fileNameID=$download.href  -split "[=;]" -replace "&amp"
			$FileName=$fileNameID[1] 
			$FileID=$fileNameID[3]
			
			$NameLinks = $download.outerHTML -split "[><]"
			
			$outFolder= outFolder $download.outerHTML $downloadFolder
					
			$downloadFiles=$outFolder + $Fileid+"_"+$FileName
   
   			$downloadURL=("http://brokenstone.ru/" + $download.href) -replace "amp;"
   			
			
				$properties = @{'downloadURL'=$downloadURL;
	                			'downloadFiles'=$downloadFiles;
								'NameLinks'=$NameLinks[2];
								'NameFile'=$Fileid+"_"+$FileName;
								'idFiles'=$FileID;
	                		}
			$URL1 = New-Object –TypeName PSObject –Prop $properties
			
			if ($OldUrls1 | Where-Object {(($_.idFiles -eq $URL1.idFiles) -and ($_.NameFile -eq $URL1.NameFile))}) {
			
						$OldUrlsTemp+=$URL1
			}

						else {
												
						$URLS1+=$URL1
			}
		
	}
 			
return $URLS1, $OldUrlsTemp
		
}
#загрузка файла
function DownloadFiles {
    $DownUrls=@()

	$getURLs = getURL $webRequest.links $downloadFolder
	
	
	if ($getURLs[0].count -eq 0){
	
	write-log -Message "Нет новых файлов для загрузки"  #-Path $logfile
	
	}
	
	else {
   
	  foreach ($url in $getURLs[0]) {
     	 		
		
		$start_time = Get-Date
		$webRequest1=Invoke-WebRequest $URL.downloadURL -WebSession $session # -PassThru -outfile $URL.downloadFiles
		
		Switch  ($webRequest1.BaseResponse.ContentType) {
		
				'application/octet-stream' {
		
		
		[io.file]::WriteAllBytes($URL.downloadFiles,$webRequest1.Content)
        $DownUrls+=$url
		Write-log -Message ("Файл "+$url.NameFile+ " загружен за $((Get-Date).Subtract($start_time).Seconds) second(s)") #-Path $logfile
		
		write-log -Message ("Загружен файл " + $url.NameFile)  #-Path $logfile
			}	
		
				default {
				
					write-log -Message ("ContentType  в заголовке ответа не соотвесвует 'application/octet-stream' файл не загружен, возвращенный ContentType = " + $webRequest.BaseResponse.ContentType)  #-Path $logfile
				}
			}
		
		
		}
	}
Export-Clixml ($downloadFolder + "logs/downloadurls.xml") -InputObject ($DownUrls + $getURLs[1])
write-log -Message "Работа скрипта завершена " #-Path $logfile
}
ChekFolders
#Авторизация на сайте
#Надо разобраться с формированием строки BODY POST.

#$Request = Invoke-WebRequest 'http://brokenstone.ru/account/login.aspx' -Headers $h1 -SessionVariable session



$b1='' #тут передаем куки полученые с помощью фидлера :)

#$log=Invoke-WebRequest -method POST -URI 'http://brokenstone.ru/account/login.aspx' -Body $b1 -WebSession $session -ContentType 'application/x-www-form-urlencoded'
$log=Invoke-WebRequest -method POST -URI 'http://brokenstone.ru/account/login.aspx' -Body $b1 -Headers $h1 -SessionVariable session -ContentType 'application/x-www-form-urlencoded' #-UseBasicParsing

$webRequest=Invoke-WebRequest 'http://brokenstone.ru/supplyfileexport.aspx' -WebSession $session -UseBasicParsing

if ($webRequest.links.href | Where-Object {$_ -like "*downloading.aspx*"}){
	write-log -Message "Авторизация удалась - Здравствуйте,Avtostrada!" #-Path $logfile
	
	DownloadFiles

			
	} else {
			write-log -Message "Авторизация не удалась" #-Path $logfile
			
	}
