$argss = $args[0]
$paramsArray =$argss.Split("?")

$Assem = (“Microsoft.SqlServer.Management.Sdk.Sfc”, 
“Microsoft.SqlServer.Smo”, 
“Microsoft.SqlServer.ConnectionInfo”,
“Microsoft.SqlServer.SqlEnum”);

Add-Type -AssemblyName $Assem

$SmoServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $paramsArray[0]
$SmoServer.ConnectionContext.LoginSecure = $false
$SmoServer.ConnectionContext.set_Login($paramsArray[3])
$SmoServer.ConnectionContext.set_Password($paramsArray[4])
$db = $SmoServer.Databases[$paramsArray[2]]   

$Objects = $db.Tables                                                                
$Objects += $db.Views         
$Objects += $db.StoredProcedures
$Objects += $db.UserDefinedFunctions
$Objects += $db.Tables.Indexes
$Objects += $db.Tables.Triggers

foreach ($CurrentObject in $Objects) 
{     
    if (-not $CurrentObject.IsSystemObject )
        { 
            $Scripter = New-Object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SmoServer)
            $Scripter.Options.DriAll = $True;
            $Scripter.Options.ScriptSchema = $True;
            $Scripter.Options.ScriptData  = $False;
            $Scripter.Options.NoCollation = $True;
            $Scripter.Script($CurrentObject);
            Write-Output "GO`n" 
        }
}