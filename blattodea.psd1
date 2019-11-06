<# 
.TODO
    RequiresModules - rm AWSPowerShell, ++ AWS.Tools.*
    * AWS.Tools.EC2
    * AWS.Tools.ElasticLoadBalancingV2

.LINK
    https://github.com/aws/aws-tools-for-powershell/issues/33
#>
@{
    RootModule = 'blattodea.psm1'
    ModuleVersion = '0.0.0'
    Author = 'Peter Vandivier'
    RequiredModules = @('AWSPowerShell') # 'powershell-yaml'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    ScriptsToProcess = @('./classes.ps1')
}