---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraComponent/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraComponent/
---
# Add-JiraComponent

## SYNOPSIS

Adds a new Component to Jira

## SYNTAX

### Name

```powershell
Add-JiraComponent [-Name] <String> [-Description] <String> [-Project] <Object> [-Credential <PSCredential>] [<CommonParameters>]
```

### ByProject

```powershell
Add-JiraComponent [-Project] <Object[]> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified component from Jira.

Components are specific to a Project.
Therefore, it is not possible to query for Components without a project.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraComponent -Name "Database"
```

Adds a new component with name "Database"

### EXAMPLE 2

```powershell
Add-JiraComponent -Name "Database" -Description "The SQL Server database"
```

Adds a new component with name "Database" and description of "The SQL Server database"

## PARAMETERS

### -Name

The Name of the component to add.

```yaml
Type: String
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

The Description of the component.

```yaml
Type: String

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## OUTPUTS

### [JiraPS.Component]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `component` have not yet been implemented in the module.

## RELATED LINKS
