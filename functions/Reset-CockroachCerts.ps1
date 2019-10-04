function Reset-CockroachCerts {
<#
.DESCRIPTION
    in the event you've borked your certs, this function iterates through your nodes and re-configures them
    only tested versus the cockroach CA issuance. does not create a new CA

.LINK
    https://www.cockroachlabs.com/docs/stable/create-security-certificates.html

.EXAMPLE
    $splat = @{
        Cluster = (Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances
        LoadBalancer = Get-Content ./conf/actual/LoadBalancer.json | ConvertFrom-Json
        CertsDir = $btd_Defaults.CertsDirectory
        OtherNames = '*.elb.us-east-2.amazonaws.com'
    }
    Reset-CockroachCerts @splat

.TODO
    Errorchecking, pipelining?, ssh timeout+handling
#>
    [cmdletbinding()]Param(
        [Parameter(Mandatory=$true)][object[]]$Cluster,
        [Parameter(Mandatory=$true)][object]$LoadBalancer,
        [Parameter(Mandatory=$true)]$CertsDir,
        [string]$AWSRegion = $StoredAWSRegion,
        $IdentityFile = (Resolve-Path -Path "conf/secret/$($btd_Defaults.KeyPair.Name).pem"),
        [string]$User = 'centos',
        [string]$OtherNames = $null,
        [switch]$NewCA
    )
    begin{
        $PopRegion = $StoredAWSRegion
        Set-DefaultAWSRegion $AWSRegion

        $IdentityFile = (Resolve-Path $IdentityFile).Path

        if(-not (Test-Path $CertsDir)){
            New-Item -Path $CertsDir  -ItemType Directory | Out-Null
        }
        $CertsDir = (Resolve-Path $CertsDir).Path 

        Push-Location $CertsDir
        
        New-Item -Path certs             -ItemType Directory -ErrorAction SilentlyContinue
        New-Item -Path my-safe-directory -ItemType Directory -ErrorAction SilentlyContinue

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
            if($node.InstanceId){
                $PublicIpAddress = $node.PublicIpAddress

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

                dsh -i $IdentityFile $User@$PublicIpAddress 'rm -rf certs; mkdir certs'
                dcp -i $IdentityFile -r certs/ $User@$PublicIpAddress`:~/
                dsh -i $IdentityFile $User@$PublicIpAddress 'sudo rm -rf /var/lib/cockroach/certs'
                dsh -i $IdentityFile $User@$PublicIpAddress 'sudo mv -f certs /var/lib/cockroach/'
                dsh -i $IdentityFile $User@$PublicIpAddress 'sudo chown -R cockroach.cockroach /var/lib/cockroach'
                dsh -i $IdentityFile $User@$PublicIpAddress 'sudo systemctl restart securecockroachdb'

                Get-ChildItem -Path certs/node* | Remove-Item
            }else{
                Write-Error "Node could not be parsed as an EC2 Instance."
            }
        }
    }

    end{
        Pop-Location
        Set-DefaultAWSRegion $PopRegion
    }
}
