

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
    begin
    {
        #if there are multiple colors defined then split them up
        if ($color -like "*,*")
        {
            $Colorchoices = @($Color.split(","))
            #get the number of colors we are using
            [int]$Colorcount = $Colorchoices.count
        }
        #If there is only one color defined, then use it
        else
        {
            $Colorchoices = $Color
        }
    }
    process {
        #If we are to color each char in the string of text
        if ($colorchars) 
        {
            [int]$count = 0
            #Are we just doing a single word or breaking into chars
            $Messagechars = $text.Length
            0..$Messagechars | Foreach-object {
            if ($count -eq $Colorcount)
            {
                $count = 0
            }
            write-host $text[$_] -ForegroundColor $Colorchoices[$count] -NoNewline
            $count++
            }
        }
        else 
        {
            #See if we are doing a single word or multiple words / multiple colors
            if ($color -like "*,*")
            {
                [int]$count = 0
                #split the message up using the space and iterate each one
                $Messagefix = $text.replace(" "," ~ ")
                $Messagefix.Split(" ") | Foreach-object {
                    if ($count -eq $Colorcount) {
                        $count = 0
                    }
                    if ($_ -eq "~") {
                        write-host " " -NoNewline
                        $count = $count-1
                    }
                    else {
                        write-host $_ -ForegroundColor $Colorchoices[$count] -NoNewline
                    }
                    $count++
                }
            }
            else
            {
                Write-Host $text -ForegroundColor $Colorchoices -NoNewline
            }
        }
    }
}

function New-wordleword {
    begin {
        $Words = @(((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/charlesreid1/five-letter-words/master/sgb-words.txt").toupper()).split())
    }
    process {
        Get-Random $Words
    }
}
function New-WordleGame {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $UseEmojiResponse
    )
    begin {
        [string]$Word = New-wordleword
        [int32]$count = 0
        [array]$notletters = @()
        [array]$guessedletter = @()

"
 _    _  _____  ____  ____  __    ____ 
( \/\/ )(  _  )(  _ \(  _ \(  )  ( ___)
 )    (  )(_)(  )   / )(_) ))(__  )__) 
(__/\__)(_____)(_)\_)(____/(____)(____)

Guess the WORDLE in 6 tries.

The WORDLE word is 5 characters long.
After each guess, the color of the letter will change to show you how close your guess was to the word.

"

write-tocolor -color Green -text "GREEN means the letter is in the word and in the correct spot"
write-host " "
write-tocolor -color Yellow -text "YELLOW means the letter is in the word but in the wrong spot"
write-host " "
write-tocolor -color DarkGray -text "GRAY means the letter is not in the word"
write-host " "
    }
    process {
        do {
            if ($notletters.count -gt 0)
            {
                write-tocolor -color DarkGray -text "The following letters are not in the word: $notletters"
                write-host " "
            }
            $guessedletter = @()
            $InText = ((read-host "Please guess a five letter word").ToUpper())
            if ($InText.length -ne 5)
            {
                write-warning "Your guess must be 5 characters long"
            }
            else 
            {
                $count++
                #see if the letter is correct
                0..4 | Foreach-object {
                    
                    [string]$char = $InText[$_]
                    $guessedletter += $char
                    #See how many instances of the guessed letter there are in the word
                    [int]$Appearances = $word.Length - $word.replace("$Char","").Length
                    #See how many times we have guessed the current letter
                    [int]$GuessedCount = ($guessedletter | Where-object {$_ -eq $char}).count
                    if ($Guessedcount -gt $Appearances)
                    {
                        if ($UseEmojiResponse)
                        {
                            Write-Host "⬛" -NoNewline
                        }
                        else 
                        {
                            write-tocolor -text $InText[$_] -color "DarkGray"
                        }
                        if ($InText[$_] -notin $notletters)
                            {
                                $notletters += $InText[$_]
                            }
                    }
                    else {
                        if ($InText[$_] -eq $Word[$_])
                        {
                            if ($UseEmojiResponse)
                            {
                                Write-Host "🟩" -NoNewline
                            }
                            else 
                            {
                                write-tocolor -text $InText[$_] -color "Green"
                            }
                        }
                        #if the letter is in the word but in the wrong spot
                        elseif($word.contains("$char"))
                        {
                            if ($UseEmojiResponse)
                            {
                                Write-Host "🟨" -NoNewline
                            }
                            else 
                            {
                                write-tocolor -text $InText[$_] -color "Yellow"
                            }
                        }
                        elseif ($InText[$_] -notin $Word)
                        {
                            if ($UseEmojiResponse)
                            {
                                Write-Host "⬛" -NoNewline
                            }
                            else 
                            {
                                write-tocolor -text $InText[$_] -color "DarkGray"
                            }
                            if ($InText[$_] -notin $notletters)
                            {
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
        until(($InText -eq $Word) -or ($Count -eq 6))
    }
    end
    {
        if ($InText -ne $Word)
        {
            write-tocolor -text "You Lose!" -color "Red"
            write-host " "
            write-host "The word was: $Word"
        }
        else {
            write-tocolor -text "You Win!" -color "Green"
        }
    }
}




