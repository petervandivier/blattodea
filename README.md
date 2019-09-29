# blattodea

## 🦆 cockroachdb deployment scratchpad

Redeployable scripts for cockroachdb demo & teardown.

* [AWSPowershell docs][1]
* [CockroachDB walkthrough (AWS) (pretty)][2]

## Usage

Requires Powershell Core

Edit the conf/aws templates to your desired configuration & save without the `.example` suffix. Or just use all the defaults ¯\\\_(ツ)_/¯.

```pwsh
Get-ChildItem ./conf/aws | For-EachObject {
    Copy-Item $_ -Destination ($_.FullName -replace '.example')
}
```

Currently the module is only meant for ephemeral deployment and teardown. Finalized attributes should get dumped to `conf/aws/actual` outside git versioning. Presently this is used only for reference and teardown

```pwsh
Import-Module ../blattodea

. make/cluster
. make/loadbalancer
```

> TODO: ENI, RTB, DOPT, ACL tags @ cluster
> 
> TODO: ¿ injest `conf/aws/actual`'s on `import` for management functionality?

## Cleanup

```pwsh
Import-Module ../blattodea

. destroy/loadbalancer
. destroy/cluster
```

[1]: https://docs.aws.amazon.com/powershell/latest/reference/
[2]: https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html
