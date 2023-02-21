function Add-JiraComponent {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [String]
        $Name,

        [String]
        $Description,

        [Parameter(ParameterSetName = 'ByLeadUserName', ValueFromPipelineByPropertyName)]
        [String]$LeadUserName,

        [Parameter(ParameterSetName = 'ByLeadAccountId', ValueFromPipelineByPropertyName)]
        [string]$LeadAccountId,

        [ValidateSet('PROJECT_DEFAULT', 'COMPONENT_LEAD', 'PROJECT_LEAD', 'UNASSIGNED')]
        [string]
        $AssigneeType = "PROJECT_DEFAULT",

        [ValidateScript(
            {
                if (("JiraPS.Project" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter")
                    $errorId = 'ParameterType.NotJiraProject'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Project. Expected [JiraPS.Project] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $Project,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/component"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{
            'name'         = $Name
            'description'  = $Description
            'project'      = $Project
            'assigneeType' = $AssigneeType
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByLeadUserName') {
            Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-LeadName' has been marked as deprecated. For more information, please read the help."
            $requestBody += @{
                'leadUserName' = $LeadUserName
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByLeadAccountId') {
            $requestBody += @{
                'leadAccountId' = $LeadAccountId
            }
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        if ($PSCmdlet.ShouldProcess($Name)) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraComponent -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
