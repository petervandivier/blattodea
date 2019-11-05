function Test-EC2Instance {
<#
.DESCRIPTION
    I'm not disposing of conf/actual files after destruction because of _reasons_ (mostly error handling)
    Therefore, I want to one-liner an existence assertion. I can't find a way to gracefully test _just one_ instance
    so I'm pulling down all EC2 instances from a region and iterating through $.RunningInstance's

.PARAMETER Exists
    Return truthy/falsey only instead of an object

.EXAMPLE
    @(
        (Get-EC2Instance).RunningInstance[0].InstanceId
        'i-abc'
        'i-foo'
        1
        $null
    ) | Test-EC2Instance

.EXAMPLE 
    Test-EC2Instance 'i-foo' -Region 'us-east-1' -Exists
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        # TODO: support right-side [string[]] input
        $InstanceId,
        [Parameter()]
        # TODO: ¿ValueFromPipelineByPropertyName?
        [string]
        $Region = $StoredAWSRegion,
        [Parameter()]
        [switch]
        $Exists
    )
    begin{
        $ec2 = Get-EC2Instance -Region $Region
        $Instances = @()
    }
    process{
        $node = $ec2.RunningInstance | Where-Object InstanceId -eq $InstanceId

        $Instances += [pscustomobject]@{
            InstanceId = $InstanceId
            Exists = [bool]$node
            Name = ($node.Tags | Where-Object Key -eq Name).Value
        }
    }
    end{
        if($Exists){
            return $Instances.Exists
        } else {
            return $Instances
        }
    }
}
