function Get-PSWordleUpdate {
    begin {
        [string]$version = "0.0.8"
        try { 
            [string]$PublishedVersion = (Invoke-RestMethod "https://raw.githubusercontent.com/bwya77/PSModules/main/PSWordle/version.txt").Trim()
        } 
        catch {
            $_.Exception.Response.StatusCode.Value__
        }
    }
    Process {
        if (($version -ne $PublishedVersion) -and ($PublishedVersion.count -gt 0)) {
            [string]$Message = "A new version of PSWordle is available! 
Current version: $version
Published version: $PublishedVersion
Please run Update-Module -Name PSwordle to grab the latest version.

Note: You can hide the update message by including the -IgnoreUpdates parameter when starting a new game"
        }
    }
    End {
        $Message
    }
}
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
        if ([System.Environment]::OSVersion.Platform -eq "Unix") {
            [string]$configFile = "$env:HOME\PSWordle\config.json"
        }
        Else {
            [string]$configFile = "$env:APPDATA\PSWordle\config.json"
        }
    }
    Process {
        $myObject = [PSCustomObject]@{
            $configItemName = $configItemValue
        }
        #export myObject to JSON
        $myObject | ConvertTo-Json | Out-File $configFile -Force
    }
}
function Get-ConfigFile {
    Begin {
        if ([System.Environment]::OSVersion.Platform -eq "Unix") {
            [string]$configFile = "$env:HOME\PSWordle\config.json"
        }
        Else {
            [string]$configFile = "$env:APPDATA\PSWordle\config.json"
        }
    }
    Process {
        if (-not(Test-Path -Path $configFile)) {
            #New-Item -ItemType Directory -Path $configFile -Force | Out-Null
            New-Item -ItemType File -Path $configFile -Force | Out-Null
        }
    }
    End {
        $configFile
    }
}
function Get-ConfigItem {
    param (
        [Parameter()]
        [string]
        $configItem,
        [Parameter()]
        [string]
        $configFile
    )
    Process {
        #get the configured username
        $userName = (Get-Content -Raw -Path $configFile -erroraction:SilentlyContinue | ConvertFrom-Json).$configItem
    }
    End {
        $userName
    }
}
function Get-PSWordleDictionary {
    Begin {
        $Platform = [System.Environment]::OSVersion.Platform
    }
    Process {
        if ($Platform -eq "Unix") {
            #Get dictionary file
            $dictionary = Select-String "^[a-z]{5}$" "$PSScriptRoot/src/dictionary.txt"
        }
        #If we are on Windows
        Else {
            #Get dictionary file
            $dictionary = Select-String "^[a-z]{5}$" "$PSScriptRoot\src\dictionary.txt"
        }
    }
    End {
        $dictionary
    }
}
function New-PSWordleWord {
    begin {
        #Figure out what platform we're on
        $Platform = [System.Environment]::OSVersion.Platform
        #If we are on Unix
        if ($Platform -eq "Unix") {
            #Get 5 letter words from the files
            $words = Select-String "^[a-z]{5}$" "$PSScriptRoot/src/words.txt"   
        }
        #If we are on Windows
        Else {
            #Get 5 letter words from the files
            $words = Select-String "^[a-z]{5}$" "$PSScriptRoot\src\words.txt"
        }
    }
    process {
        #Get a random word from the word list
        Get-Random $Words
    }
}
function New-PSWordleUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $userName
    )
    Begin {

    }
    Process {
        While ($true) {
            Write-Host "Checking online to see if that username is available"
            $Check = Get-PSWordleLeaderboardUser -username $userName -Uri "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="

            # It's returning a string not a boolean so I need to format the IF statement this way
            if ($Check -eq "True") {
                Write-Host "That username is already taken! Please enter a new one." -ForegroundColor Yellow
                $userName = Read-Host -Prompt "Please enter a new UserName "
            }
            else {
                Write-Host "Success! Username is available" -ForegroundColor Green; break
            }
        }
    }
    End {
        Set-ConfigItem -ConfigItemName username -ConfigItemValue $username
        $userName
    }
}
function Get-PSWordleLeaderBoard {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Uri = "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="
    )
    begin{
        $Platform = [System.Environment]::OSVersion.Platform
    }
    process{
        $Param = @{
            Uri  = $Uri
            Body = @{
                "Request" = "Results"
            }
        }
        $Results = Invoke-WebRequest @Param
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
function Get-PSWordleLeaderboardUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $userName,
        [Parameter(Mandatory)]
        [string]
        $Uri

    )
    begin
    {
        $Param = @{
            Uri = $Uri
            Body = @{
                "Request"  = "CheckUser"
                "Username" = $username
            }
        }
    }
    Process
    {
        $Results = Invoke-WebRequest @Param
    }
    End 
    {
        $Results.Content
    }
}
function Set-PSWordleScore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $User,
        [Parameter(Mandatory)]
        [int]
        $Score,
        [Parameter(Mandatory)]
        [string]
        $Uri
    )
    Begin {
        $Param = @{
            Uri  = $Uri
            Body = @{
                "Request"  = "CheckUser"
                "Username" = $user
            }
        }
        $Results = Invoke-WebRequest @Param 
    }
    Process {
        #If our user is currently on the leaderboard we need to adjust the score
        if ($Results.Content -eq 'True') {
            $ModifiedDateTime = get-date -Format yyyyMMdd:HHmmss
            $Param = @{
                Uri   = $Uri
                Body = @{
                    "Request"          = "AddUser"
                    "Username"         = $User
                    "Score"            = $Score
                    "ModifiedDateTime" = $ModifiedDateTime
                    "IsPresent"        = "true"
                }
            }
            $Results = Invoke-WebRequest @Param 
        }
        #if our user is not currently on the leaderboard, we can just add their score
        else {
            $CreatedDateTime = get-date -Format yyyyMMdd:HHmmss
            $Param = @{
                Uri = $Uri
                Body = @{
                    "Request"          = "AddUser"
                    "Username"         = $User
                    "Score"            = $Score
                    "ModifiedDateTime" = $CreatedDateTime
                    "CreatedDateTime"  = $CreatedDateTime
                    "IsPresent"        = "false"
                }
            }
            $Results = Invoke-WebRequest @Param 
        }
    }
    End
    {
        $Results.Content
    }
}
Function Get-MatchedItems {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Guess,
        [Parameter()]
        [string]
        $Word
    )
    Begin {
        [array]$changechars = @()
        [int]$count = -1
        [string]$guessNew = ""
    }
    Process {
        0..4 | ForEach-Object {
            $count++
            if ($guess[$_] -eq $word[$_]) {
                $changechars += $count
            }
        }
        [int]$count = -1
        
        $Guess.ToCharArray() | ForEach-Object {
            $Count++
            if ($count -in $changechars) {
                $guessNew += $_
            }
            Else {
                $guessNew += "*"
            }
        }
    }
    End {
        $guessNew.toupper()
    }
}
Function New-PSWordleGame {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]
        $CompeteOnline,
        [Parameter()]
        [Switch]
        $HardMode,
        [Parameter()]
        [Switch]
        $IgnoreUpdates,
        [Parameter()]
        [Switch]
        $UseEmojiResponses
    )
    Begin {
        if (-not($IgnoreUpdates))
        {
            $Info = Get-PSWordleUpdate
            if (-not([string]::IsNullOrWhiteSpace($info))) {
                Write-Host $Info -ForegroundColor Yellow
            }
        }
        #region <start> Username items
        if ($CompeteOnline) {

            #Get the config file, if none exists, the function will create it and return the path
            $configFile = Get-ConfigFile
            #Read the config file and extract the username
            [string]$userName = Get-ConfigItem -ConfigItem username -ConfigFile $configFile
            if ([string]::IsNullOrWhiteSpace($userName))
            {
                $userNameAttempt = Read-Host "Please enter a username you wish to use"
                $userName = New-PSWordleUser -userName $userNameAttempt
            }
        }
        #Get a new random word
        $Word = New-PSWordleWord
        #Get Dictionary words
        $dictionaryWords = Get-PSWordleDictionary
        #Int counter to keep track of the number of times we have tried to guess the word
        [int]$guessCount = 1
        $wordleShare = "", "", "", "", "", "", ""
        #For hard mode, keep an array of correctly guessed letters
        [array]$correctLetters = @()
        [hashtable]$correctLetterPlacement = @{}
        #Create a variable to hold the letters that have been guessed
        [array]$guessedLetters = @()
        #Create a empty hashtable / dictionary that will hold letters that are NOT in the word
        [string[]]$notLetters = @()
        #Keep a table of the points for each guess
        [hashtable]$pointlookup = @{
            1 = 10
            2 = 8
            3 = 6
            4 = 4
            5 = 2
            6 = 1
        }
            #region <start> New game prompt and directions
            "
 _  _   __  ____  ____  __    ____ 
/ )( \ /  \(  _ \(    \(  )  (  __)
\ /\ /(  O ))   / ) D (/ (_/\ ) _) 
(_/\_) \__/(__\_)(____/\____/(____)
                       "
                       if ($CompeteOnline) {
                           Write-Host -ForegroundColor Green "Welcome back: $username!"
               "
Get points based on how quickly you can guess the word!
If you guess the word in the first try, you get 10 points.
2nd try: 8 points
3rd try: 6 points
4th try: 4 points
5th try: 2 points
6th try: 1 point
If you don't guess it at all you will lose 1 point.
"
                   }
                   if ($HardMode)
                   {
"
Any revealed hints must be used in subsequent guesses. Green letters must remain in the correct position.
"
                   }
"The WORDLE word is 5 characters long."
Write-Host -ForegroundColor Green "GREEN" -NoNewline; Write-Host " means the letter is in the word and in the correct spot"
Write-Host -ForegroundColor Yellow "YELLOW" -NoNewline; Write-Host " means the letter is in the word but in the wrong spot"
Write-Host -ForegroundColor DarkGray "GRAY" -NoNewline; Write-Host " means the letter is not in the word"
        #region <end>
    }
    Process {
        while ($true) {
            If ($notLetters.count -gt 0)
            {
                Write-Host "Not in the word: $($notLetters | Sort-Object)" -ForegroundColor DarkGray
            }
            #Clear the guessed letter array
            $guessedLetters = @()
            #Prompt the user for a guess
            [string]$guess = (Read-Host "($guessCount) Guess a 5-letter word").ToUpper()

            if ($HardMode)
            {
                #For hard mode, if the guess does not contain correct previously guessed letters
                if (($guess -notcontains $correctLetters) -and ($correctLetters.Count -gt 0))
                {
                    Do {
                        #Iterate through the array and see if any letters are not in the guessed word
                        if (($correctLetters| ForEach-Object{$guess.contains($_)}) -contains $false)
                        {
                            Write-Host "You must use all the correct letters from the previous guess" -ForegroundColor Red
                            #Re-prompt the user for a guess
                            $guess = (Read-Host "($guessCount) Guess a 5-letter word").ToUpper()
                        }
                    }
                    Until (($correctLetters| ForEach-Object{$guess.contains($_)}) -notcontains $false)
                }
                #for hard mode, make sure the letters that were guesed in the correct position are still in the correct position
                if ($correctLetterPlacement.count -gt 0)
                {
                    $correctLetterPlacement.GetEnumerator() | ForEach-Object {
                        #Until all the letters are in the right spot
                        While ($guess[$_.name] -ne $_.value) {
                            Write-Host "Letters shown to be in the correct spot must remain in the correct spot" -ForegroundColor Red
                            #Re-prompt the user for a guess
                            $guess = (Read-Host "($guessCount) Guess a 5-letter word").ToUpper()
                        }
                    }
                }
            }
            
            #If you guess is the word, you win
            if ($guess -eq $word.Line) {
                #If we are running on PWSH then we can use emojis
                if ($PSVersionTable.PSEdition -eq "Core")
                {
                    Write-Host
                    Write-Host "🎉💥 You Win! 💥🎉" -ForegroundColor Green; $wordleShare[$guessCount] = "🟩" * 5; break
                }
                #If we are running on Windows PowerShell then we can't use emojis
                else {
                    Write-Host
                    Write-Host "You Win!" -ForegroundColor Green; $wordleShare[$guessCount] = "*" * 5; break
                }
            }
            #If your guess is too short or too long
            if ($guess.Length -ne 5) {
                Write-Host "Your guess must be 5 letters!" -ForegroundColor Red; continue 
            }
            #If the guess appears to not be a valid word
            if ($guess -notin $dictionaryWords.Line) {
                Write-Host "That word is not in our dictionary, please try again." -ForegroundColor Red ; continue 
            }
            #Get all letters that have been guessed in the correct spots
            [string]$Matches = Get-MatchedItems -Guess $Guess -Word $Word.line
            #for (<Init>; <Condition>; <Repeat>) { <Body> }
            #for 5 loops, do the following ( start at 0, while the number is less than 5 run the block, afterwards increment the number by 1)
            for ($pos = 0; $pos -lt 5; $pos++) {
                $shareImage = "⬛️"
                #Add guessed letters to the array
                
                #region <start> Reduce letter false positives
                $guessedLetters += $guess[$pos]
                #See how many instances of the guessed letter there are in the word
                [int32]$Appearances = ($Word.line[0..4] -eq $guess[$pos]).count
                #If we have guessed the letter more than it appears in the word
                    if ($guess[$pos] -eq $word.Line[$pos]) {
                        #Add the letter to the correct letters array
                        $correctLetters += $guess[$pos]

                        #Hard mode: Add correct letters and their placement in the hashtable
                        if ($HardMode) {
                            if ($correctLetterPlacement.Keys -notcontains $pos) {
                                [string]$Key = $pos
                                [string]$Value = $word.Line[$pos]
                                #Add our guessed letter to the hashtable / dictionary
                                $correctLetterPlacement.Add($Key, $Value)
                            }
                        }
                        if ($UseEmojiResponses) {
                            Write-Host "🟩" -NoNewLine; $shareImage = "🟩" 
                        }
                        else {
                            Write-Host -ForegroundColor Green $guess[$pos] -NoNewLine; $shareImage = "🟩" 
                        }
                    }
                    #If the letter is in the word, but not in the correct position, we have guessed the letter, but not the correct position
                    elseif ($guess[$pos] -in $word.Line.ToCharArray()) {
                        # If the letter appears once, and its in the $Matches string indicating that its in the correct spot, then any other instance of the letter is incorrect
                        if (($Appearances -eq 1) -and ($Matches.ToCharArray() -contains $guess[$pos])) {
                            if ($UseEmojiResponses) {
                                Write-Host "⬛️" -NoNewLine; $shareImage = "⬛️" 
                            }
                            else {
                                Write-Host -ForegroundColor DarkGray $guess[$pos] -NoNewLine; $shareImage = "⬛️" 
                            }
                        }
                        # Get the letters from the guessed word up until the current letter and then see how many times the current character appears
                        # Then get the times the current letter appears in the word
                        # If the guessed letter is stil lower than the total times it shows up in the word, then its valid but in the wrong spot
                        elseif(($guess[0..$pos] -eq $guess[$pos]).Count -le ($word.Line.ToCharArray() -eq $guess[$pos]).Count) {
                            #Add the letter to the correct letters array
                            $correctLetters += $guess[$pos]
                            if ($UseEmojiResponses) {
                                Write-Host "🟨"  -NoNewLine; $shareImage = "🟨" 
                            }
                            else {
                                Write-Host -ForegroundColor Yellow $guess[$pos] -NoNewLine; $shareImage = "🟨" 
                            }
                        }
                        Else {
                            #Add the letter to the correct letters array
                            $correctLetters += $guess[$pos]
                            if ($UseEmojiResponses) {
                                Write-Host "⬛️" -NoNewLine; $shareImage = "⬛️" 
                            }
                            else {
                                Write-Host -ForegroundColor DarkGray $guess[$pos] -NoNewLine; $shareImage = "⬛️" 
                            }
                        }
                    }
                    else {
                        if ($UseEmojiResponses) {
                            Write-Host "⬛️" -NoNewLine
                        }
                        else {
                            Write-Host -ForegroundColor DarkGray $($guess[$pos]) -NoNewLine 
                        }
                        if (-not($notLetters -contains $guess[$pos])) {
                            #Add our guessed letter to the array
                            $notLetters += $guess[$pos]
                        }
                    }
                
                $wordleShare[$guessCount - 1] += $shareImage 
            }
    
            $guessCount++
            if ($guessCount -eq 7) {
                #If you did not guess the word in 6 guesses, replace the guess counter with a X
                [string]$guessCount = "X"
                Write-Host; Write-Host "Too many guesses! The right word was: '$($word.Line.toupper())'"
                break 
            }
            Write-Host
        }
    }
    End {
        If ($CompeteOnline) {
            #using the hashtable, figure out how many points we get based on how quickly we guessed the word
            if ($guessCount -eq 'X') {
                $Points = -1
            }
            Else {
                $points = $pointlookup[$guessCount] 
            }
            write-host " "
            if ($Points -eq 1) {
                Write-Host "You have earned $points point!" 
            }
            else {
                Write-Host "You have earned $points points!" 
            }
            Write-Host "Adding your score to the leaderboard..."
            Set-PSWordleScore -user $username -Score $points -uri "https://funpswordle.azurewebsites.net/api/wordleleaderboard?code=LesznI7agk9vyt3pEu1YCb4ehbo4Mz1lQHewvRfgaw/FNOPXQMiSLg=="
        }
        #If we are running on PWSH or Windows PowerShell, if Windows PowerShell we cannot display emojis
        if ($PSVersionTable.PSEdition -eq "Core") {
            Write-Host "PSWORDLE $($word.LineNumber) $guessCount/6`r`n"
            $wordleShare | Where-Object { $_ }
        }
        Else {
            #Display the line number the wordle word was found on as well as how many guesses it took
            Write-Host "PSWORDLE $($word.LineNumber) $guessCount/6`r`n"
        }
    }
}