# https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/

using namespace System.Management.Automation

class ValidBtdPositionGenerator : IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $btd_VPC = Get-Content "./conf/target/VPC.json" -Raw | ConvertFrom-Json
        $Values = $btd_VPC.PSObject.Properties.Name
        return $Values
    }
}
