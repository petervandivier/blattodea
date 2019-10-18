function Build-CrdbCerts {
<#
.DESCRIPTION
    in the event you've borked your certs, this function iterates through your nodes and re-configures them
    only tested versus the cockroach CA issuance. 

    For example, if you need to destroy and re-create your load balancer, you will need to re-issue certs to 
    your nodes to allow traffic from the new load balancer name. Or you could wildcard it as seen in the example below

.LINK
    https://www.cockroachlabs.com/docs/stable/create-security-certificates.html

.EXAMPLE
    # The following usage will re-issue certs using the existing CA to a running cluster

    $splat = @{
        Cluster      = (Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances
        LoadBalancer = Get-Content ./conf/actual/LoadBalancer.json | ConvertFrom-Json
        CertsDir     = $btd_Defaults.CertsDirectory
        OtherNames   = '*.elb.us-east-2.amazonaws.com'
        Clobber      = $true
    }
    Build-CrdbCerts @splat

.TODO
    pipelining?

.PARAMETER NewCA
    Initializes a new Certificate Authority

.PARAMETER Clobber
    Expects to find a running securecockroachdb service on the target host. 
    Destroys existing certs and restarts the service
#>
    [cmdletbinding()]Param(
        [Parameter(Mandatory=$true)][object[]]$Cluster,
        [Parameter(Mandatory=$true)][object]$LoadBalancer,
        [Parameter(Mandatory=$true)]$CertsDir,
        $IdentityFileDir = (Resolve-Path -Path "./conf/secret"),
        [string]$User = 'centos',
        [string]$OtherNames = $null,
        [switch]$NewCA,
        [switch]$Clobber
    )
    begin{

        $errMsg = @"
Node missing required elements. Certficate issuance skipped.
- IdentityFile : '{0}'
- PublicIpAddress : '{1}
"@

# weirdly, -Force is a -NoClobber action here ¯\_(ツ)_/¯
# it suppresses the error message & still returns the fully qualified path
        $CertsDir = (New-Item -Path $CertsDir -ItemType Directory -Force).FullName
        
        Push-Location $CertsDir
        
        New-Item -Path certs             -ItemType Directory -Force
        New-Item -Path my-safe-directory -ItemType Directory -Force

        Get-ChildItem -Path certs/node* | Remove-Item

        if($NewCA){
            Get-ChildItem -Path certs, my-safe-directory | Remove-Item

            cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key
        }

        $elbPublicIpAddress = (dig $LoadBalancer.DNSName +short) -join ' '

        $createCertCmdTemplate = "cockroach cert create-node {0} {1} {2} {3} localhost 127.0.0.1 {4} {5} {6} --certs-dir=certs --ca-key=my-safe-directory/ca.key"
    }

    process{
        foreach($node in $cluster){
            $IdentityFile = (Resolve-Path "$IdentityFileDir/$($node.KeyName).pem").Path
            $PublicIpAddress = $node.PublicIpAddress

            if($null -in ($IdentityFile,$PublicIpAddress)){
                Write-Error $errMsg -f @($IdentityFile,$PublicIpAddress)
            }else{
                $createCertCmd = $createCertCmdTemplate -f @(
                    $node.PrivateIpAddress # 0 
                    $node.PublicIpAddress  # 1 
                    $node.PrivateDnsName   # 2 
                    $PublicIpAddress       # 3 
                    $elbPublicIpAddress    # 4 
                    $LoadBalancer.DNSName  # 5 
                    $OtherNames            # 6 
                )
                Invoke-Expression -Command $createCertCmd 

                dsh -i $IdentityFile -o ConnectTimeout=5 $User@$PublicIpAddress 'rm -rf certs; mkdir certs'
                dcp -i $IdentityFile -o ConnectTimeout=5 -r certs/ $User@$PublicIpAddress`:~/

                if($Clobber){
                    dsh -i $IdentityFile -o ConnectTimeout=5 $User@$PublicIpAddress 'sudo rm -rf /var/lib/cockroach/certs'
                    dsh -i $IdentityFile -o ConnectTimeout=5 $User@$PublicIpAddress 'sudo mv -f certs /var/lib/cockroach/'
                    dsh -i $IdentityFile -o ConnectTimeout=5 $User@$PublicIpAddress 'sudo chown -R cockroach.cockroach /var/lib/cockroach'
                    dsh -i $IdentityFile -o ConnectTimeout=5 $User@$PublicIpAddress 'sudo systemctl restart securecockroachdb'
                }
                
                Get-ChildItem -Path certs/node* | Remove-Item
            }
        }
    }

    end{
        Pop-Location
    }
}
