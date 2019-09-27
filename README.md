# blattodea

## 🦆 cockroachdb deployment scratchpad

Redeployable scripts for cockroachdb demo & teardown.

* [AWSPowershell docs][1]
* [CockroachDB walkthrough (AWS) (pretty)][2]

## Usage

Requires Powershell Core

Edit the conf/aws templates to your desired configuration & save without the `.example` suffix. 

```pwsh
Import-Module ../blattodea

. make/cluster
```

TODO: ENI, RTB tags @ cluster

[1]: https://docs.aws.amazon.com/powershell/latest/reference/
[2]: https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html
