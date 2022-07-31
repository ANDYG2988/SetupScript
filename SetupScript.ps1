#Setup Script V0.8
Set-ExecutionPolicy RemoteSigned

#powershell.exe -ep RemoteSigned "C:\Users\$env:UserName\Desktop\Code.ps1"


$loop = 1;

Write-Output = "Welcome to the Andrew's Powershell installation and Setup Script";  #Welcome message


function installPrograms{
            
    #installation of programs will begin depending previous choices
    
    write-output "`nInstallation of selected Programs will begin now`n"
   

    #List of Programs
    $list = @( "google.chrome", "Adobe.Acrobat.Reader.32-bit", "7zip.7zip" , "microsoft.office"<#, "TheDocumentFoundation.LibreOffice"#>)

    for($i = 0; $i -le $list.length -1 ; $i++){
             winget install $list[$i] 
            } 
}#End of Install

function uninstallPrograms{

    $pro = @("MSC", "35ED3F83-4BDC-4c44-8EC6-6A8301C7413A", "4DF9E0F8.Netflix_mcm4njqhnhss8", "Disney.37853FC22B2CE_6rarf9sa4v8jt", "Spotify.Spotify", "SpotifyAB.SpotifyMusic_zpdnekdrzrea0"
            ,"Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe","Microsoft.XboxApp_8wekyb3d8bbwe", "Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe",
            "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe", "Microsoft.XboxGameOverlay_8wekyb3d8bbwe", "Microsoft.Xbox.TCUI_8wekyb3d8bbwe","Amazon.com.Amazon_343d40qqvtj1t", "C27EB4BA.DropboxOEM_xbfy0k16fey96" );

    foreach($program in $pro){
        winget uninstall $program -h
    }
}#End of Uninstall



function setPower{
#Change power amd timer settings
$breakLine
Write-Host "would you like to change power option to High Performance?"
$changePower = Read-Host "type Y for yes. anything else will cancel this step"
$breakLine
    if($changePower -eq "y" -OR $changePower -eq "Y" ){

        #High Power Performance
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }

#Power Timers
    Powercfg /Change monitor-timeout-ac 5 #screentimout 5 minutes
    Powercfg /Change monitor-timeout-dc 5 #screentimout 5 minutes
    Powercfg /Change standby-timeout-ac 0 #sleep never
    Powercfg /Change standby-timeout-dc 0 #sleep never
    # Powercfg /change hibernate-timeout-ac 0 #Hibernate never
    # Powercfg /change hibernate-timeout-dc 0 #Hibernate never
    powercfg /hibernate off

}#End of SetPower

function startProgram(){

    while ($loop -eq 1) {

        Write-Host "Below are a list of functions you can start`n";
        Write-Host "1) Install Programs`n2) Uninstall Unnecessary Programs`n3) Set Power Settings`n"; 
        $all = Read-Host -Prompt "Would you like to start all Processes?`n[Y]Yes to All [N] NO [E] to Exit`n";

        if($all -eq "y" -OR $all -eq "Y"){
            setPower
	    uninstallPrograms
            installPrograms
            
            $loop = 0;
        }elseif ($all -eq "n" -OR $all -eq "N") {
            $loop2 = 1;

            while ($loop2 -eq 1) {

                Write-Output "`nPlease select the function to start"
                $choice = Read-Host -Prompt "1) Install Programs`n2) Uninstall Unnecessary Programs`n3) Set Power Settings`n4) to Exit`n";
                if($choice -eq 1){
                    installPrograms
                }elseif($choice -eq 2){
                    uninstallPrograms
                }elseif($choice -eq 3){
                    setPower
                }elseif($choice -eq 4){
                    $loop2 = 0;
                }else{
                    Write-Host "`nSorry i didn't get that`n";
                }

            }
        }elseif($all -eq "e" -OR $all -eq "E"){
            $loop = 0;
        }else{
            Write-Host "`nSorry i didn't get that`n"
        }

    }#end of while Loop

}

startProgram
Read-host -prompt "`nThank you for using Andrew's Installation at Setup Script`n"