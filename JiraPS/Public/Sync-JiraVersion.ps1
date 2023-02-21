function Sync-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, ValueFromPipeline, ParameterSetName = 'byProjects' )]
        [String[]]
        $Project,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $null = Get-JiraConfigServer -ErrorAction Stop

        Write-Progress -Activity "Syncing Project Versions" -Status "0% Complete" -PercentComplete 0

        $updated = 0
        $created = 0
        $versionCount = 0
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projects = @()
        if ($PSCmdlet.ParameterSetName -eq "_All") {
            $projects += Get-JiraProject
        } elseif ($PSCmdlet.ParameterSetName -eq "byProjects") {
           foreach ($project in $Project) {
                $projects += Get-JiraProject $project
            }
        }

        if ($projects.Count -gt 0) {

            $versions = (Get-JiraVersion -Key $projects.Key)

            if ($versions.Count -gt 0) {

                foreach ($_project in $projects) {

                    $versions

                    foreach ($version in $versions | Where-Object -FilterScript { $_.Project -eq $_project.ID } ) {

                        if ($components.Count -gt 0) {
                            $i = [int](($versionCount++ / $components.Count) * 100)
                            if ($null -eq $i -or $i -eq 0) {
                                $i = 1
                            }
                        } else {
                            $i = 1
                        }
                        Write-Progress -Activity "Syncing Project Versions - Current Project: $($_project.Name)" -Status "$i% Complete" -PercentComplete $i

                        $newComp = $null

                        foreach ($pr2 in $projects | Where-Object -FilterScript { $_.Key -ne $_project.Key } ) {

                            $v2 = ($versions | Where-Object -FilterScript { $_.Project -eq $pr2.ID -and $_.Name -eq $version.Name } | Select-Object -First 1)

                            if ($null -ne $v2) {

                                $a = ($version | Select-Object -Property name, description, releaseDate, archived, released, startDate)
                                $b = ($v2 | Select-Object -Property name, description, releaseDate, archived, released, startDate)

                                if ((Compare-Object $a $b -Property name, description, releaseDate, archived, released, startDate| Where-Object{ $_.SideIndicator -ne '==' }).Count -gt 0) { #if not equal

                                    # this creates a pseduo 2-way sync - a wins else the first b wins (subsequent bs are not considered)
                                    if ($null -eq $newVersion) {
                                        $newVersion = Join-PSCustomObject -MergeObjects $a, $b
                                        if ($null -eq $newVersion) {
                                            $newVersion = $a
                                        }
                                    }

                                    if ((Compare-Object $a $newComp -Property name, description, releaseDate, archived, released, startDate | Where-Object { $_.SideIndicator -ne '==' }).Count -gt 0) {
                                        if ($PSCmdlet.ShouldProcess($Project, "Version Update to $($newVersion.Name) in $($pr2.Name)")) {
                                            Set-JiraVersion -Id $version.id -Name $newVersion.name -Description $newVersion.description -ReleaseDate $newVersion.releaseDate -Archived $newVersion.archived -Released $newVersion.released -StartDate $newVersion.startDate
                                        }
                                        $updated = + 1
                                    }

                                    if ((Compare-Object $b $newComp -Property name, description, releaseDate, archived, released, startDate | Where-Object { $_.SideIndicator -ne '==' }).Count -gt 0) {
                                        if ($PSCmdlet.ShouldProcess($Project, "Version Update to $($newVersion.Name) in $($pr2.Name)")) {
                                            Set-JiraVersion -Id $v2.id -Name $newVersion.name -Description $newVersion.description -ReleaseDate $newVersion.releaseDate -Archived $newVersion.archived -Released $newVersion.released -StartDate $newVersion.startDate
                                        }
                                        $updated = + 1
                                    }
                                }
                            }
                            else {
                                # if not found in the comparison project then add it
                                if ($PSCmdlet.ShouldProcess($Project, "Version Creation of $($version.Name) in $($pr2.Name)")) {
                                    Add-JiraVersion -ProjectCode $pr2 -Name $version.name -Description $version.description -ReleaseDate $version.releaseDate -Archived $version.archived -Released $version.released -StartDate $version.startDate
                                }
                                $created += 1
                            }
                        }
                    }
                }
            }
        }

        Write-Output @{
            Total   = $versions.Count
            Updated = $updated
            Created = $created
        }
    }

    end {
        Write-Progress -Activity "Completed Syncing Project Versions" -Status "100% Complete" -PercentComplete 100
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
