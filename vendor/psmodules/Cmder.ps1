function readVersion($gitPath) {
    $gitExecutable = "${gitPath}\git.exe"

    if (!(test-path "$gitExecutable")) {
        return $null
    }

    $gitVersion = (cmd /c "${gitExecutable}" --version)

    if ($gitVersion -match 'git version') {
        ($trash1, $trash2, $gitVersion) = $gitVersion.split(' ', 3)
    } else {
        return $null
    }

    return $gitVersion.toString()
}

function isGitShim($gitPath) {
    # check if there's shim - and if yes follow the path

    if (test-path "${gitPath}\git.shim") {
      $shim = (get-content "${gitPath}\git.shim")
      ($trash, $gitPath) = $shim.replace(' ','').split('=')

      $gitPath=$gitPath.replace('\git.exe','')
    }

    return $gitPath.toString()
}

function Register-LatestPathCommandVersion([string]$Path, [string]$Command) {
    <#
    .SYNOPSIS
        Set latest git version in $ENV:PATH
    .DESCRIPTION
        Check users path and known cmder paths and use the latest version of git.

        Validated in Cmder.tests.ps1
    #>

    # Expected locations to test for Git
    @(
        "git-for-windows\cmd",
        # guess if mingw is present and check its git too.
        "mingw32\bin",
        "mingw64\bin",
        # Guess if the user has provided git for some reason
        "usr\bin"
    ).foreach({
            # Resolve relative directories to the path. If the path doesn't exist then eat the error and continue
            Join-Path $ENV:CMDER_ROOT $psItem -Resolve -ErrorAction SilentlyContinue
        }).foreach( {
            $Path = $Path.insert(0, "$psitem;")
        })

    [System.Collections.ArrayList]$existingEnv = $Path.split(';')

    # Descending sort all git versions, skip the newest only getting the paths, split off the Command and remove those paths.
    get-command -all -ErrorAction SilentlyContinue $Command |
        sort-object Version -Descending |
        Select-Object -Skip 1 -ExpandProperty Source |
        Split-Path |
        ForEach-Object {
            $existingEnv.Remove($psItem)
        }

    return $existingEnv -join ';'
}

function Import-Git(){

    $GitModule = Get-Module -Name Posh-Git -ListAvailable
    if($GitModule | select version | where version -le ([version]"0.6.1.20160330")){
        Import-Module Posh-Git > $null
    }
    if(-not ($GitModule) ) {
        Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
    }
    # Make sure we only run once by alawys returning true
    return $true
}

function checkGit($Path) {
    if (Test-Path -Path (Join-Path $Path '.git') ) {
      if($env:gitLoaded -eq 'false') {
        $env:gitLoaded = Import-Git
      }

      if (getGitStatusSetting -eq $true) {
        Write-VcsStatus
      }

      return
    }
    $SplitPath = split-path $path
    if ($SplitPath) {
        checkGit($SplitPath)
    }
}

function getGitStatusSetting() {
    $gitStatus = (git --no-pager config -l) | out-string

    ForEach ($line in $($gitStatus -split "`r`n")) {
        if ($line -match 'cmder.status=false' -or $line -match 'cmder.psstatus=false') {
            return $false
        }
    }

    return $true
}
