#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe 'Add-JiraComponent' -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $name = "Component Name"
        $description = "Component Description"
        $leadUserName = "Component lead user name"
        $leadAccountId = "Component lead account id"
        $assigneeType = "PROJECT_DEFAULT"

        $projectKey = 'IT'
        $projectId = '10003'
        $projectName = 'Information Technology'

        $project = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ParameterFilter { $Key -eq $issueKey } {
            $object = [PSCustomObject]@{
                Key = $issueKey
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/component" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            return $true
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Add-JiraComponent

            defParam $command 'Name'
            defParam $command 'Description'
            defParam $command 'LeadUserName'
            defParam $command 'LeadAccountId'
            defParam $command 'AssigneeType'
            defParam $command 'Project'
            defParam $command 'Credential'
        }

        Context "Functionality" {

            It 'Adds a new Component' {
                { Add-JiraComponent -Name $name -Description $description -Project $project } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It 'Validates the Project provided' {
                $projectTest = [PSCustomObject]@{ type = "projectTest" }
                { Add-JiraComponent -Issue $issueKey -Project $projectTest } | Should Throw
            }

            It 'Validates pipeline input object' {
                { "projectTest" | Add-JiraComponent -Project $projectTest } | Should Throw
            }
        }
    }
}
