Describe 'Cmder helper functions' {
    BeforeAll {
        . ./Cmder.ps1

        $ENV:CMDER_ROOT = "TestDrive:\"

        $knownPaths = [PSCustomObject]@{
            ven = Join-Path $ENV:CMDER_ROOT "git-for-windows\cmd\git.exe"
            w32 = Join-Path $ENV:CMDER_ROOT "mingw32\bin\git.exe"
            w64 = Join-Path $ENV:CMDER_ROOT "mingw64\bin\git.exe"
            usr = Join-Path $ENV:CMDER_ROOT "usr\bin\git.exe"
        }
        Function Get-Command() {
            $MockGits = @(
                [PSCustomObject]@{ Version = [version]"2.3.1" ; Source = $knownPaths.ven },
                [PSCustomObject]@{ Version = [version]"3.1.1" ; Source = $knownPaths.w32 }
                [PSCustomObject]@{ Version = [version]"2.19.1"; Source = $knownPaths.w64 },
                [PSCustomObject]@{ Version = [version]"4.0"   ; Source = $knownPaths.usr }
            )
            return $MockGits.where({Test-path (split-path $psItem.Source) })
        }

        $Path = "C:\Program Files\PowerShell\7;C:\WINDOWS\system32;C:\WINDOWS;C:\Program Files\Git\cmd"
        function Prepare-GitTestPath($p) {
            <#
            .SYNOPSIS
                Setup the required directory to check paths with
            .DESCRIPTION
                Checking for git version in the path mocks the actual git version check
                This handles makeing folder paths exists for the logic to run against.

                Also returns the path it created in case that's what you expect the test ti find.
            .EXAMPLE
                PS C:\> $expect = Prepare-GitTestPath $knownPaths.ven
                Save the path you want to end up wit hto check after testing
            .EXAMPLE
                PS C:\> Prepare-GitTestPath $knownPaths.ven > $null
                Discart path but create directory to test
            #>
            $dir = (split-path $p)
            New-Item -ItemType Directory -Path $dir > $null
            return [string]::Format("{0};{1}", $dir, $Path)
        }
    }
    AfterEach{
        Remove-Item -Recurse TestDrive:\*
    }
    It 'Only Vendor git exists.' {
        $expect = Prepare-GitTestPath $knownPaths.ven

        $UpdatedPath = Register-LatestPathCommandVersion -Path $Path -Command "git"
        $UpdatedPath | Should -Be $expect
    }
    It 'Only user path exists.' {
        $expect = Prepare-GitTestPath $knownPaths.usr

        $UpdatedPath = Register-LatestPathCommandVersion -Path $Path -Command "git"
        $UpdatedPath | Should -Be $expect
    }
    It 'Highest git version when multiple' {
        Prepare-GitTestPath $knownPaths.w64 > $null
        $expect = Prepare-GitTestPath $knownPaths.w32

        $UpdatedPath = Register-LatestPathCommandVersion -Path $Path -Command "git"
        $UpdatedPath | Should -Be $expect
    }
}
