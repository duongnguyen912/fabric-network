## Fabric Multi-Host Network (BMHN)




## Prerequisites/Node Install

```
$ sudo usermod -aG docker $USER \
 sudo add-apt-repository ppa:webupd8team/java \
 sudo apt-get update \
 sudo apt-get install oracle-java8-installer \
 sudo apt-get install maven \
 curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - \
 sudo apt-get install -y nodejs  \


$ git clone -b master https://github.com/hyperledger/fabric-samples.git \
 cd fabric-samples \
 git checkout v1.1.0-rc1 \
 curl -sSL https://goo.gl/6wtTN5 | bash -s 1.1.0-rc1 \

#install golang

$ wget https://dl.google.com/go/go1.10.linux-amd64.tar.gz
$ sudo tar -C /usr/local -xzf go1.10.linux-amd64.tar.gz

$ echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile && \
 echo 'export GOPATH=$HOME/go' | tee -a $HOME/.bashrc && \
 echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' | tee -a $HOME/.bashrc && \
 mkdir -p $HOME/go/{src,pkg,bin} \
 echo 'export PATH=$PATH:$HOME/fabric-samples/bin' | tee -a $HOME/.bashrc

```


### Network Topology
So the network that we are going to build will have the following below components. For this example we are using two PCs lets say (PC1 and PC2):

```
A Certificate Authority (CA) — PC1
An Orderer — PC1
1 PEER (peer0) on — PC1
1 PEER (peer1) on — PC2
CLI on — PC2
```


### Before You Start

Before starting we also need to do this step. Run the following command to kill any stale or active containers:
Clear any cached networks:
Press 'y' when prompted by the command

```
$ docker rm -f $(docker ps -aq)
$ docker volume rm $(docker volume ls -q)
$ docker network prune
```


Before You Start
Initialize a swarm: (docker swarm documentation for more information)
$ docker swarm init
$ docker swarm init --advertise-addr 34.236.53.156

Join the swarm with the other host as a manager (PC1 will create swarm and PC2 will join it)
PC1:

$ docker swarm join-token manager
It will output something like this

```
    docker swarm join — token SWMTKN-1–3as8cvf3yxk8e7zj98954jhjza3w75mngmxh543llgpo0c8k7z-61zyibtaqjjimkqj8p6t9lwgu 172.16.0.153:2377
    We will copy it(the one on your terminal, not the one above) and execute it on PC2 terminal to make it join PC1
```
use the output command of the previous command on PC2

Create a network (“my-net” in my case) — 
```
$ docker network create --attachable --driver overlay my-net
```

See more docker swarm network:

* https://docs.docker.com/network/network-tutorial-overlay/#walk-through
* https://github.com/docker/labs/blob/master/networking/tutorials.md



Clone this repo on both the PCs i.e PC1 and PC2.

```
$ git clone https://github.com/phuongdo/fabric-network.git
```

### Setting up the Network
On PC1 :
The below scripts will run on PC1. Execute each command in a separate terminal.

Also make sure that you are in “fabric-netwoork” folder before executing any of the script. The scripts utilizes the files in the “fabric-netwoork” folder and will throw error if it can’t locate it.

```
$ docker-compose -f docker-compose-host1.yml -up -d
```

On PC2:
The following below command will be executed on PC2.

Make sure that you are in “fabric-network” folder before executing any of the script. The scripts utilizes the files in the “fabric-network” folder and will throw error if it can’t locate it.


```
$ docker-compose -f docker-compose-host2.yml -up -d
```

### Testing the Network

Create the channel

```
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
```


Join peer0.org1.example.com to the channel.

```
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" cli peer channel join -b mychannel.block
```

Query
```
#docker exec -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051"  cli peer chaincode install -n mycc2 -v 1.0 -p github.com/chaincode_example02
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051"  cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051"  cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["invoke","a","b","20"]}'
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
```

# Adding an Org to a Channel

### Setup the Environment

We will be operating from the root of the `fabric-network` subdirectory within your local clone of `fabric-network`.
Change into that directory now. You will also want to open a few extra terminals for ease of use.

Bring Org3 into the Channel with the Script
You should be in first-network. To use the script, simply issue the following:

```
./eyfn.sh up

```

The output here is well worth reading. You’ll see the Org3 crypto material being added, the config update being created and signed, and then chaincode being installed to allow Org3 to execute ledger queries.

If everything goes well, you’ll get this message:

```
========= All GOOD, EYFN test execution completed ===========
```

eyfn.sh can be used with the same Node.js chaincode and database options as byfn.sh by issuing the following (instead of ./byfn.sh -m -up):

```
./byfn.sh up -c testchannel -s couchdb -l node
```

And then:

```
./eyfn.sh up -c testchannel -s couchdb -l node
```

## Manually Stup

### Generate the Org3 Crypto Material

```
cd org3-artifacts
cryptogen generate --config=./org3-crypto.yaml
export FABRIC_CFG_PATH=$PWD && configtxgen -printOrg Org3MSP > ../channel-artifacts/org3.json
cd ../ && cp -r crypto-config/ordererOrganizations org3-artifacts/crypto-config/

```

ON `cli` Org1

```
docker exec -e "CHANNEL_NAME=mychannel" -e "ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/ca/ca.example.com-cert.pem" -it cli bash
apt update && apt install -y jq
```
Then execute these commands :

```
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/ca/ca.example.com-cert.pem && export CHANNEL_NAME=mychannel
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME  --cafile $ORDERER_CA
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org3_update.pb
configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json
configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb
```

### Sign and Submit the Config Update

```
peer channel signconfigtx -f org3_update_in_envelope.pb
peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --cafile $ORDERER_CA

```

### Join Org3 to the Channel


```
docker-compose -f docker-compose-org3.yaml up -d
docker exec -e "CHANNEL_NAME=mychannel" -e "ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/ca/ca.example.com-cert.pem" -it Org3cli bash

```

ON `Org3cli` Org3

```
peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c $CHANNEL_NAME --cafile $ORDERER_CA
peer channel join -b mychannel.block
```

### Upgrade and Invoke Chaincode

From the Org3 CLI:

```
peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/
```

From the Org1 CLI:

```
peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/
peer chaincode upgrade -o orderer.example.com:7050 --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.member','Org2MSP.member','Org3MSP.member')"
```

From the Org3 CLI:

```
#docker exec -e "CORE_PEER_ADDRESS=peer0.org3.example.com:7051" Org3cli peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'
peer chaincode invoke -o orderer.example.com:7050  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}'
```
