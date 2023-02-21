function Join-PSCustomObject {
    <#
	.SYNOPSIS
		Combines multiple objects into a single object.

	.DESCRIPTION
		Combines multiple objects into a single object.
		On multiple identic properties, the last wins.

	.EXAMPLE
		PS C:\> Join-PSCustomObjects -MergeObjects $Obj1, $Obj2

		Merges the PS custom objects contained in $Obj1 and $Obj2 into a single PS Custom object.
#>
    [CmdletBinding()]
    Param (
        # The tables to merge.
        [Parameter( Mandatory, ValueFromPipeline )]
        [AllowNull()]
        [PSCustomObject[]]
        $MergeObjects
    )
    begin {
        $newObject = New-Object -TypeName PSObject
    }

    process {
        $combinedMembers = @()

        foreach ($object in $MergeObjects) {
            if ($object.gettype().BaseType.Name -eq 'Object') {
                $combinedMembers += Get-Member -InputObject $object -MemberType NoteProperty
            }
            else {
                Write-Warning "This item is NOT an object:`r`n$object"
            }
        }

        foreach ($property in $combinedMembers) {
            $propertyName = $property.Name
            $value = $property.Definition -replace '^.*='

            $propertyExists = $propertyName -in ($newobject | get-member).Name
            if (!$propertyExists) {
                Add-Member -InputObject $newObject -MemberType NoteProperty -Name $propertyName -Value $value -Force
            }
        }
    }

    end {
        $newObject
    }
}
