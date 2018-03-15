## Fabric Multi-Host Network (BMHN)



### Network Topology
So the network that we are going to build will have the following below components. For this example we are using two PCs lets say (PC1 and PC2):

A Certificate Authority (CA) — PC1
An Orderer — PC1
1 PEER (peer0) on — PC1
1 PEER (peer1) on — PC2
CLI on — PC2



Before starting we also need to do this step. Run the following command to kill any stale or active containers:
Clear any cached networks:
Press 'y' when prompted by the command
```
docker rm -f $(docker ps -aq)
docker network prune

```




Step 2 : Clone the sample git repository or extract the zip file


Clone this repo on both the PCs i.e PC1 and PC2.
$ git clone https://github.com/phuongdo/fabric-network.git





