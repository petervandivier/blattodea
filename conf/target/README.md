# Target Configuration

Documents in this directory are injested by the [utils](../../utils.ps1) script during `Import-Module` and exported as PSObject global variables with the same name as the base file prefixed with `btd_`. These global variables are referenced in turn in the `make/` scripts to define submit the desired configuration to the AWS API. 
