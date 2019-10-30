When scripting out the peering, I noticed that the "requester" and "accepter" attributes persist on the VPC elements even after configuration is completed. I do not get the impression that this is a productive difference; but all the same, it got me thinking about the balance of attributes between different VPCs as you scale up from 1->2->3+ VPCs in a peering configuration. 

For example: when adding a third node, do you prefer the "Default" VPC to be the requester for #3. For the 2<->3 peering, which do you choose as the accepter? Or do you "round-robin" so each VPC gets a balanced number of "requester" vs "accepter" assignments. Perfectly balanced ratios are only possible in configurations with an odd number of node-VPCs (e.g.: a 4-VPC peering cluster requires each node-VPC to have 3 distinct relationships - thus 2/1 or 1/2 (or 0/3 / 3/0)). 

Regardless of which you "prefer", when scripting out an arbitrary config, you need to choose how your round-robin is going to work. I scratched up the below grid &  colocated diagrams when thinking this through. 

```
                             = points-1
          =(points*node-vectors)/2       
          =(points*(points-1))/2       
          =(p^2-p)/2
  nodes   peering-
  VPCs      connections   
+--------+---------+-------+--------------+
| points | vectors | edges | node-vectors |
+--------+---------+-------+--------------+
|   0    |   0     |   0   |       0      |
|   1    |   0     |   0   |       0      |
|   2    |   1     |   1   |       1      |
+--------+---------+-------+--------------+ 
|   3    |   3     |   3   |       2      |
|   4    |   6     |   4   |       3      |
|   5    |   10    |   5   |       4      |
|   6    |   15    |   6   |       5      |
+--------+---------+-------+--------------+
```

----

Other observations of note: 
* The `pcx-*` peering connection ID is common between both VPCs it relates too
* Tags on the PCX object are scoped to each VPC
  * This means the same PCX may have different names in VPC-1 vs VPC-2
* I'm not sure what the sensible choice is vs. naming a PCX the same on each side or having the per-side name reflect which side the name is on
