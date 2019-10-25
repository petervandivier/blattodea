# blattodea

## 🦆 cockroachdb deployment scratchpad

Redeployable scripts for cockroachdb demo & teardown. Rubber-ducking ftw

* [AWSPowershell docs][1]
* [CockroachDB walkthrough (AWS) (pretty)][2]

## Usage

Requires Powershell Core

Copy the [conf/example](conf/example) templates to [conf/target](conf/target) and edit to your desired configuration. Or just use all the defaults ¯\\\_(ツ)_/¯.

```pwsh
Copy-Item ./conf/example/* -Destination ./conf/target/
```

> TODO: ¿support profiles?

Currently the module is only meant for ephemeral deployment and teardown. Finalized attributes should get dumped to `conf/actual` outside git versioning. Presently this is used actively for reference and teardown

```pwsh
Import-Module ../blattodea

. ./make-all.ps1
```

## Cleanup

```pwsh
Import-Module ../blattodea

. ./destroy-all.ps1
```

[1]: https://docs.aws.amazon.com/powershell/latest/reference/
[2]: https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html
