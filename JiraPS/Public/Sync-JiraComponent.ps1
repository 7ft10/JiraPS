function Sync-JiraComponent {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byProjects' )]
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

        Write-Progress -Activity "Syncing Project Components" -Status "0% Complete" -PercentComplete 0

        $updated = 0
        $created = 0
        $compCount = 0
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

        $components = (Get-JiraComponent -Project $projects)

        if ($components.Count -gt 0) {

            foreach ($_project in $projects) {

                foreach ($component in $components | Where-Object -FilterScript { $_.ProjectId -eq $_project.ID } ) {

                    $i = [int](($compCount++ / $components.Count) * 100)
                    Write-Progress -Activity "Syncing Project Components - Current Project: $($_project.Name)" -Status "$i% Complete" -PercentComplete $i

                    $count = (Get-JiraComponentRelatedIssueCount -id $component.ID).IssueCount

                    if ($count -gt 0) {

                        $newComp = $null

                        foreach ($pr2 in $projects | Where-Object -FilterScript { $_.Key -ne $_project.Key } ) {

                            $comp2 = ($components | Where-Object -FilterScript { $_.ProjectName -eq $pr2.Key -and $_.Name -eq $component.Name } | Select-Object -First 1)

                            if ($null -ne $comp2) {

                                $a = ($component | Select-Object -Property Name, Description)
                                $b = ($comp2 | Select-Object -Property Name, Description)

                                if ((Compare-Object $a $b -Property Name, Description | Where-Object { $_.SideIndicator -ne '==' }).Count -gt 0) {

                                    # this creates a pseduo 2-way sync - a wins else the first b wins (subsequent bs are not considered)
                                    if ($null -eq $newComp) {
                                        $newComp = Join-PSCustomObject -MergeObjects $a, $b
                                    }

                                    if ((Compare-Object $a $newComp -Property Name, Description | Where-Object { $_.SideIndicator -ne '==' }).Count -gt 0) {
                                        if ($PSCmdlet.ShouldProcess($Project, "Component Update to $($newComp.Name) in $($pr2.Name)")) {
                                            Set-JiraComponent -Id $component.id -Name $newComp.Name -Description $newComp.Description
                                        }
                                        $updated = + 1
                                    }

                                    if ((Compare-Object $b $newComp -Property Name, Description | Where-Object { $_.SideIndicator -ne '==' }).Count -gt 0) {
                                        if ($PSCmdlet.ShouldProcess($Project, "Component Update to $($newComp.Name) in $($pr2.Name)")) {
                                            Set-JiraComponent -Id $comp2.id -Name $newComp.Name -Description $newComp.Description
                                        }
                                        $updated = + 1
                                    }
                                }
                            }
                            else {
                                # if not found in the comparison project then add it
                                if ($PSCmdlet.ShouldProcess($Project, "Component Creation of $($component.Name) in $($pr2.Name)")) {
                                    Add-JiraComponent -Project $pr2 -Name $component.Name -Description $component.Description
                                }
                                $created += 1
                            }
                        }
                    }
                }
            }
        }

        Write-Output @{
            Total   = $components.Count
            Updated = $updated
            Created = $created
        }
    }

    end {
        Write-Progress -Activity "Completed Syncing Project Components" -Status "100% Complete" -PercentComplete 100
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
