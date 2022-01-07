using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
import-module -Name az.accounts, aztable, az.storage, Az.Resources

Write-Output "Connecting to azure via  Connect-AzAccount -Identity" 
Connect-AzAccount -Identity 
Write-Output "Successfully connected with Automation account's Managed Identity" 

$ctx = New-AzStorageContext -StorageAccountName "sawordleleaderboard" -StorageAccountKey $env:storagekey
$cloudTable =  (Get-AzStorageTable –Name 'leaderboard' -Context $ctx).cloudtable

#If we are adding a new user
if ($Request.Query.Request -eq "AddUser")
{
    if ($Request.Query.IsPresent -eq "false")
    {
        $Guid = New-Guid
        [string]$User = $Request.Query.Username
        [int32]$Score = $Request.Query.Score
        if ($Score -lt 0)
        {
            [int32]$Score = 0
        }
        $ModifiedDateTime = $Request.Query.ModifiedDateTime
        $CreatedTimestamp = $request.Query.CreatedDateTime
        Add-AzTableRow `
        -table $cloudTable `
        -partitionKey 'partition1'`
        -rowKey ("$($Guid.Guid)") -property @{"PlayerTag"="$User";"Score"=$Score;"CreatedDateTime"=$CreatedTimestamp;"ModifiedDateTime"=$ModifiedDateTime}
        $allscores = (Get-AzTableRow -Table $cloudTable).Score | sort-object -Descending 
        [int]$place = ($allscores.indexof("$Score")) + 1
        $Outbody = "Successfully added to the leaderboard! Your place in the leaderboard: $place/$($allscores.Count) `
Run Get-PSWordleLeaderBoard to view the leaderboard."
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $Outbody
        })
    }
    Else
    {
        [string]$User = $Request.Query.Username
        # Set filter.
        [string]$filter = `
        [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PlayerTag",`
        [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"$User")

        # Retrieve entity to be deleted, then pipe it into the remove cmdlet.
        $userToDelete = Get-AzTableRow `
            -table $cloudTable `
            -customFilter $filter

        [int32]$Currentscore = $userToDelete.Score
        [string]$CreatedTimestamp = $userToDelete.CreatedDateTime
        $ModifiedDateTime = $Request.Query.ModifiedDateTime
        $Guid = $userToDelete.RowKey

        [int32]$Score = [int32]$Request.Query.Score + [int32]$Currentscore
        if ($Score -lt 0)
        {
            [int32]$Score = 0
        }

        #Delete the row
        $userToDelete | Remove-AzTableRow -table $cloudTable

        #Add the row back with the new data
        Add-AzTableRow `
        -table $cloudTable `
        -partitionKey 'partition1'`
        -rowKey $Guid -property @{"PlayerTag"="$User";"Score"=$Score;"CreatedDateTime"=$CreatedTimestamp;"ModifiedDateTime"=$ModifiedDateTime}
        $allscores= (Get-AzTableRow -Table $cloudTable).Score | sort-object -Descending
        [int]$place = ($allscores.indexof("$Score")) + 1
        $Outbody = "You now have a total of $Score points! Your place in the leaderboard: $place/$($allscores.Count) `
Run Get-PSWordleLeaderBoard to view the leaderboard."
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $Outbody
        })
    }
}

#If we are checking to see if a user exists
if ($Request.Query.Request -eq "CheckUser")
{
    #Get items from the table
    $items = Get-AzTableRow -Table $cloudTable
    $User = $Request.Query.Username
    #If our user is in the table already
    if ($User -in $Items.PlayerTag)
    {
        Write-Output "The user is present"
        $Outbody = "True"
    }
    Else
    {
        Write-Output "The user is not present"
        $Outbody = "False"
    }
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $Outbody
    })
}

#If we are requesting the results of the leaderboard
if ($Request.Query.Request -eq "Results")
{
    #Get all items in the table
    $Outbody = Get-AzTableRow -Table $cloudTable
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $Outbody
    })
}

