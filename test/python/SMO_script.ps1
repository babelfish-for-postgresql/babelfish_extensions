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
$script_flag = $paramsArray[5]
$schm = "sys"
$dtb = "sysdatabases"
$var_one = "1"
$schm1 = "dbo"
$schm2 = "guest"




if($script_flag -eq $var_one)
{
    $Objects = $db.Tables
    $Objects += $db.Views
    $Objects += $db.StoredProcedures
    $Objects += $db.UserDefinedFunctions
    $Objects += $db.Sequences
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

}
else
{
    $Objects = $db.Tables
    $Objects += $db.Views
    $Objects += $db.StoredProcedures
    $Objects += $db.UserDefinedFunctions
    $SubObjects += $db.Tables.Indexes
    $SubObjects += $db.Tables.Triggers
    $SubObjects += $db.Sequences
    $SubObjects += $db.Users

    foreach ($CurrentObject in $Objects)
    {
        if ($CurrentObject.schema -ne $schm -and $CurrentObject.schema -ne $dtb -and $CurrentObject.schema -ne $null -and -not $CurrentObject.IsSystemObject )
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
    foreach ($CurrentObject in $SubObjects)
    {
        if (-not $CurrentObject.IsSystemObject -and $CurrentObject.Name -ne $schm1 -and $CurrentObject.Name -ne $schm2)
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

}
