function Set-ConfigItem {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $configItemName,
        [Parameter()]
        [string]
        $configItemValue,
        [Parameter()]
        [string]
        $configFile
    )
    begin {

    }
    Process {
        $myObject = [PSCustomObject]@{
            $configItemName = $configItemValue
        }
        #export myObject to JSON
        $myObject | ConvertTo-Json | Out-File $configFile
    }
}

function write-tocolor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $color,
        [Parameter(Mandatory)]
        [string]
        $text,
        [Parameter()]
        [switch]
        $colorchars
    )
    begin {
        #if there are multiple colors defined then split them up
        if ($color -like "*,*") {
            $Colorchoices = @($Color.split(","))
            #get the number of colors we are using
            [int]$Colorcount = $Colorchoices.count
        }
        #If there is only one color defined, then use it
        else {
            $Colorchoices = $Color
        }
    }
    process {
        #If we are to color each char in the string of text
        if ($colorchars) {
            [int]$count = 0
            #Are we just doing a single word or breaking into chars
            $Messagechars = $text.Length
            0..$Messagechars | Foreach-object {
                if ($count -eq $Colorcount) {
                    $count = 0
                }
                write-host $text[$_] -ForegroundColor $Colorchoices[$count] -NoNewline
                $count++
            }
        }
        else {
            #See if we are doing a single word or multiple words / multiple colors
            if ($color -like "*,*") {
                [int]$count = 0
                #split the message up using the space and iterate each one
                $Messagefix = $text.replace(" ", " ~ ")
                $Messagefix.Split(" ") | Foreach-object {
                    if ($count -eq $Colorcount) {
                        $count = 0
                    }
                    if ($_ -eq "~") {
                        write-host " " -NoNewline
                        $count = $count - 1
                    }
                    else {
                        write-host $_ -ForegroundColor $Colorchoices[$count] -NoNewline
                    }
                    $count++
                }
            }
            else {
                Write-Host $text -ForegroundColor $Colorchoices -NoNewline
            }
        }
    }
}
function Set-PSWordleScore {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $user,
        [Parameter()]
        [int]
        $score
    )
    Begin
    {
        $Uri = "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="

        $body = @{
            "Request"  = "CheckUser"
            "Username" = $user
        }
        $Results = (Invoke-WebRequest -Uri $uri -Body $body).Content
        #If the user is present
        if ($Results -eq "True")
        {
            [bool]$current = $true 
        }
        #If the user is not present
        Else 
        {
            [bool]$current = $false
        }
    }
    Process 
    {
        #If our user is currently on the leaderboard we need to adjust the score
        if ($current -eq $true)
        {
            $ModifiedTimestamp = get-date -Format yyyyMMdd:HHmmss
            $body = @{
                "Request"  = "AddUser"
                "Username" = $user
                "Score"    = $Score
                "ModifiedDateTime" = $ModifiedTimestamp
                "IsPresent" = "true"
            }
            $Results = (Invoke-WebRequest -Uri $uri -Body $body).Content
        }
        #if our user is not currently on the leaderboard, we can just add their score
        else {
            $CreatedTimestamp = get-date -Format yyyyMMdd:HHmmss
            $body = @{
                "Request"  = "AddUser"
                "Username" = $user
                "Score"    = $Score
                "CreatedDateTime" = $CreatedTimestamp
                "ModifiedDateTime" = $CreatedTimestamp
                "IsPresent" = "false"
            }
            $Results = (Invoke-WebRequest -Uri $uri -Body $body).Content
            #Tell the user that we successfuly added them and tell them what place they are in the leaderboard
        }
    }
    End
    {
        $Results
    }
}
function Check-PSWordleLeaderboardUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $username
    )
    begin
    {
        $Uri = "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="
    }
    Process
    {
        $body = @{
            "Request" = "CheckUser"
            "Username" = $username
        }
        $Results = Invoke-WebRequest -Uri $uri -Body $body
    }
    End 
    {
        $Results.Content
    }
}

function Get-PSWordleLeaderBoard {
    begin{
        $Uri = "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="
        $Platform = [System.Environment]::OSVersion.Platform

    }
    process{
        $body = @{
            "Request" = "Results"
        }
        $Results = Invoke-WebRequest -Uri $uri -Body $body
    }
    end {
        #Get the results back which come back as JSON, convert to a object
            if ($Platform -eq "Unix") {
                $Results.Content | ConvertFrom-Json | select-object PlayerTag, @{N="Score"; E={[int32]$_.Score}} | sort-object Score -Descending
            }
            Else
            {
                $data = $Results.Content | ConvertFrom-Json 
                $data | select-object PlayerTag, @{N="Score"; E={[int32]$_.Score}} | sort-object Score -Descending
            }
    }
}

function New-PSWordleWord {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $hardmode
    )
    begin {

        if ($hardmode) {
            $GLOBAL:Words = @(((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/bwya77/PSModules/main/PSWordle/src/6letterwords.txt").toupper()).split())
        }
        Else {
            $GLOBAL:Words = @(((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/bwya77/PSModules/main/PSWordle/src/5letterwords.txt").toupper()).split())
        }
    }
    process {
        Get-Random $Words
    }
}
function New-PSWordleGame {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $UseEmojiResponse,
        [Parameter()]
        [switch]
        $Hardmode,
        [Parameter()]
        [switch]
        $CompeteOnline,
        [Parameter()]
        [switch]
        $ExpertMode
    )
    begin {
        [int32]$count = 0
        [array]$notletters = @()
        [array]$guessedletter = @()
        [int]$points = 0
        $pointlookup = @{
            1 = 10
            2 = 8
            3 = 6
            4 = 4
            5 = 2
            6 = 1
            7 = 1
        }
        if ($CompeteOnline) {
            #Check to see what we are running on
            $Platform = [System.Environment]::OSVersion.Platform
            if ($Platform -eq "Unix") {
                #see if our directories are present, if not then create them
                if (-not(Test-Path -Path $env:HOME\PSWordle\config.json)) {
                    New-Item -ItemType Directory -Path $env:HOME\PSWordle -Force | Out-Null
                    New-Item -ItemType File -Path $env:HOME\PSWordle\config.json -Force | Out-Null
                }
                #get the configured username
                $username = (Get-Content -Raw -Path $env:HOME\PSWordle\config.json -erroraction:SilentlyContinue | ConvertFrom-Json).username
                #If there is no username, then we need to create one
                if (-not($username)) {
                    Do
                    {
                        if ($Check -eq "True")
                        {
                            Write-Host "That username is already taken! Please enter a new one."
                        }
                        $usernameinput = Read-Host "Please enter a username you wish to use: "
                        Write-Host "Checking online to see if that username is available"
                        $Check = Check-PSWordleLeaderboardUser -username $usernameinput
                    }
                    Until ($Check -eq "False")
                    Write-Host "Success! Username is available"
                    Set-ConfigItem -ConfigItemName username -ConfigItemValue $usernameinput -configFile $env:HOME\PSWordle\config.json
                    $username = (Get-Content -Raw -Path $env:HOME\PSWordle\config.json | ConvertFrom-Json).username
                }
            }
            else {
                if (-not(Test-Path -Path $env:APPDATA\PSWordle\config.json)) {
                    New-Item -ItemType Directory -Path $env:APPDATA\PSWordle -Force | Out-Null
                    New-Item -ItemType File -Path $env:APPDATA\PSWordle\config.json -Force | Out-Null
                }
                #get the configured username
                $username = (Get-Content -Raw -Path $env:APPDATA\PSWordle\config.json | ConvertFrom-Json).username
                #If there is no username, then we need to create one
                if (-not($username)) {
                    $usernameinput = Read-Host "Please enter a username you wish to use: "
                    Set-ConfigItem -ConfigItemName username -ConfigItemValue $usernameinput -configFile $env:APPDATA\PSWordle\config.json
                    $username = (Get-Content -Raw -Path $env:APPDATA\PSWordle\config.json | ConvertFrom-Json).username
                }
            }
        }

        if ($hardmode) {
            [string]$Word = New-PSWordleWord -hardmode
            write-host "WORD IS: $Word"

        }
        else {
            [string]$Word = New-PSWordleWord

        }

        "
 _    _  _____  ____  ____  __    ____ 
( \/\/ )(  _  )(  _ \(  _ \(  )  ( ___)
 )    (  )(_)(  )   / )(_) ))(__  )__) 
(__/\__)(_____)(_)\_)(____/(____)(____)"
        " "
        if ($CompeteOnline) {
            write-tocolor -color "Red, Yellow, Blue, Green" -text "Welcome back: $username!" -colorchars

            "

Get points based on how quickly you can guess the word!
If you guess the word in the first try, you get 10 points.
2nd try: 8 points
3rd try: 6 points
4th try: 4 points
5th try: 2 points
6th try: 1 point
If you don't guess it at all you will lose 1 point."
        }
        " "
        "
Guess the WORDLE in 6 tries.

The WORDLE word is 5 characters long.
After each guess, the color of the letter will change to show you how close your guess was to the word.

"

        write-tocolor -color Green -text "GREEN means the letter is in the word and in the correct spot"
        write-host " "
        if (-not($ExpertMode))
        {
            write-tocolor -color Yellow -text "YELLOW means the letter is in the word but in the wrong spot"
            write-host " "
            write-tocolor -color DarkGray -text "GRAY means the letter is not in the word"
            write-host " "    
        }
        else {
            Write-Host "In Expert Mode only letters in the correct spot will change color. Guessed letters will not be shown."
        }
    }
    process {
        do {
            if (($notletters.count -gt 0)-and (-not($ExpertMode))) {
                write-tocolor -color DarkGray -text "The following letters are not in the word: $notletters"
                write-host " "
            }
            $guessedletter = @()
            $InText = ((read-host "Please guess a five letter word").ToUpper())
            #If the word is not in the word list, dont continue
            if (($words -contains $InText)-eq $false)
            {
                Write-host "That word is not in our dictionary, please try again." -ForegroundColor red
            }
            Else
            {
                if (($InText.length -ne 5) -and ((-not$hardmode))) {
                    write-warning "Your guess must be 5 characters long"
                }
                elseif ((($InText.length -ne 6) -and ($hardmode))) {
                    write-warning "Your guess must be 6 characters long"
                }
                else {
                    $count++
                    #see if the letter is correct
                    if ($Hardmode)
                    {
                        [int32]$until = 5
                    }
                    else
                    {
                        [int32]$until = 4
                    }
                    0..$until | Foreach-object {
                        
                        [string]$char = $InText[$_]
                        $guessedletter += $char
                        #See how many instances of the guessed letter there are in the word
                        [int]$Appearances = $word.Length - $word.replace("$Char", "").Length
                        #See how many times we have guessed the current letter
                        [int]$GuessedCount = ($guessedletter | Where-object { $_ -eq $char }).count
                        if (($Guessedcount -gt $Appearances) -and (-not($ExpertMode))) {
                            if ($UseEmojiResponse) {
                                Write-Host "⬛" -NoNewline
                            }
                            else {
                                write-tocolor -text $InText[$_] -color "DarkGray"
                            }
                            if ($InText[$_] -notin $notletters) {
                                $notletters += $InText[$_]
                            }
                        }
                        else {
                            if ($InText[$_] -eq $Word[$_]) {
                                if ($UseEmojiResponse) {
                                    Write-Host "🟩" -NoNewline
                                }
                                else {
                                    write-tocolor -text $InText[$_] -color "Green"
                                }
                            }
                            #if the letter is in the word but in the wrong spot
                            elseif ($word.contains("$char")) {
                                if($Expertmode)
                                {
                                    if ($UseEmojiResponse) {
                                        Write-Host "⬛" -NoNewline
                                    }
                                    else {
                                        write-tocolor -text $InText[$_] -color "DarkGray"
                                    }
                                }
                                Else
                                {
                                    if ($UseEmojiResponse) {
                                        Write-Host "🟨" -NoNewline
                                    }
                                    else {
                                        write-tocolor -text $InText[$_] -color "Yellow"
                                    }
                                }
                            }
                            elseif ($InText[$_] -notin $Word) {
                                if ($UseEmojiResponse) {
                                    Write-Host "⬛" -NoNewline
                                }
                                else {
                                    write-tocolor -text $InText[$_] -color "DarkGray"
                                }
                                if ($InText[$_] -notin $notletters) {
                                    $notletters += $InText[$_]
                                }
                            }
                            else {
                                write-host $InText[$_] -NoNewline
                            }
                        }
                    }
                    write-host " " 
                }  
            }         
        }
        until(($InText -eq $Word) -or ($Count -eq 6))
    }
    end {
        if ($InText -ne $Word) {
            write-tocolor -text "You Lose!" -color "Red"
            write-host " "
            write-host "The word was: $Word"
            if ($CompeteOnline)
            {
                Write-Host "You have lost 1 point."
                Write-Host "updating your score on the leaderboard..."
                Set-PSWordleScore -user $username -Score -1
            }
        }
        else {
            write-tocolor -text "You Win!" -color "Green"
            if ($CompeteOnline)
            {
                #using the hashtable, figure out how many points we get based on how quickly we guessed the word
                $points = $pointlookup[$count] 
                write-host " "
                if ($Points -eq 1)
                {
                    Write-Host "You earned $points point!" 
                }
                else {
                    Write-Host "You earned $points points!" 
                }
                Write-Host "Adding your score to the leaderboard..."
                Set-PSWordleScore -user $username -Score $points
            }
        }
    }
}




