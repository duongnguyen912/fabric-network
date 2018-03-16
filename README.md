## Fabric Multi-Host Network (BMHN)




## Prerequisites/Node Install


sudo usermod -aG docker $USER
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt-get install maven

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs


git clone -b master https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
git checkout v1.1.0-rc1
curl -sSL https://goo.gl/6wtTN5 | bash -s 1.1.0-rc1

install golang

wget https://dl.google.com/go/go1.10.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.10.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile && \
echo 'export GOPATH=$HOME/go' | tee -a $HOME/.bashrc && \
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' | tee -a $HOME/.bashrc && \
mkdir -p $HOME/go/{src,pkg,bin}

echo 'export PATH=$PATH:$HOME/fabric-samples/bin' | tee -a $HOME/.bashrc 


### Network Topology
So the network that we are going to build will have the following below components. For this example we are using two PCs lets say (PC1 and PC2):

```
A Certificate Authority (CA) — PC1
An Orderer — PC1
1 PEER (peer0) on — PC1
1 PEER (peer1) on — PC2
CLI on — PC2
```


Before You Start
Initialize a swarm: (docker swarm documentation for more information)
$ docker swarm init
Join the swarm with the other host as a manager (PC1 will create swarm and PC2 will join it)


Before starting we also need to do this step. Run the following command to kill any stale or active containers:
Clear any cached networks:
Press 'y' when prompted by the command
```
docker rm -f $(docker ps -aq)
docker volume rm $(docker volume ls -q)
docker network prune
```


Before You Start
Initialize a swarm: (docker swarm documentation for more information)
$ docker swarm init
$docker swarm init --advertise-addr 34.236.53.156

Join the swarm with the other host as a manager (PC1 will create swarm and PC2 will join it)
PC1:

$ docker swarm join-token manager
It will output something like this

docker swarm join — token SWMTKN-1–3as8cvf3yxk8e7zj98954jhjza3w75mngmxh543llgpo0c8k7z-61zyibtaqjjimkqj8p6t9lwgu 172.16.0.153:2377
We will copy it(the one on your terminal, not the one above) and execute it on PC2 terminal to make it join PC1

use the output command of the previous command on PC2

Create a network (“my-net” in my case) — PC1
$ docker network create --attachable --driver overlay my-net
Clone this repo on both the PCs i.e PC1 and PC2.

See more :

* https://docs.docker.com/network/network-tutorial-overlay/#walk-through
* https://github.com/docker/labs/blob/master/networking/tutorials.md

Step 2 : Clone the sample git repository or extract the zip file


Clone this repo on both the PCs i.e PC1 and PC2.

$ git clone https://github.com/phuongdo/fabric-network.git






Setting up the Network
On PC1 :
The below scripts will run on PC1. Execute each command in a separate terminal.

Also make sure that you are in “fabric-netwoork” folder before executing any of the script. The scripts utilizes the files in the “fabric-netwoork” folder and will throw error if it can’t locate it.

1. CA Server:
You will execute this command on PC1. before you do so, replace {put the name of secret key} with the name of the secret key. You can find it under ‘./crypto-config/peerOrganizations/org1.example.com/ca/’.

docker run -d --network="my-net" --name ca.example.com -p 7054:7054 -e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server -e FABRIC_CA_SERVER_CA_NAME=ca.example.com -e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem -e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/{put the name of secret key} -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/ca/:/etc/hyperledger/fabric-ca-server-config -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hyp-net hyperledger/fabric-ca sh -c 'fabric-ca-server start -b admin:adminpw -d'


docker run -d --network="my-net" --name ca.example.com -p 7054:7054 -e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server -e FABRIC_CA_SERVER_CA_NAME=ca.example.com -e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem -e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/cb04eb7d8a26a7a6ae98f4b5672f4da2177b969ad033ecf1dc4891a3e8b12bfc_sk -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/ca/:/etc/hyperledger/fabric-ca-server-config -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hyp-net hyperledger/fabric-ca sh -c 'fabric-ca-server start -b admin:adminpw -d'



2. Orderer
Execute this command to spawn up the orderer on PC

docker run -d --network="my-net" --name orderer.example.com -p 7050:7050 -e ORDERER_GENERAL_LOGLEVEL=debug -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 -e ORDERER_GENERAL_LISTENPORT=7050 -e ORDERER_GENERAL_GENESISMETHOD=file -e ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block -e ORDERER_GENERAL_LOCALMSPID=OrdererMSP -e ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp -e ORDERER_GENERAL_TLS_ENABLED=false -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -v $(pwd)/channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block -v $(pwd)/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp -w /opt/gopath/src/github.com/hyperledger/fabric hyperledger/fabric-orderer orderer

3. CouchDB 0 — for Peer 0
This command will spawn a couchDB instance that will be used by peer0 for storing peer ledger.

docker run -d --network="my-net" --name couchdb0 -p 5984:5984 -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=adminpwd -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net hyperledger/fabric-couchdb


4. Peer 0
And now we execute this command to spawn peer0

docker run -d --link orderer.example.com:orderer.example.com --network="my-net" --name peer0.org1.example.com -p 8051:7051 -p 8053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpwd -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer0.org1.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer0.org1.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051 -e CORE_PEER_TLS_ENABLED=false -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_LOCALMSPID=Org1MSP -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start


On PC2:
The following below command will be executed on PC2.

Make sure that you are in “fabric-network” folder before executing any of the script. The scripts utilizes the files in the “fabric-network” folder and will throw error if it can’t locate it.

5. CouchDB 1 — for Peer 1
This command will spawn a couchDB instance that will be used by peer1 for storing peer ledger. We will execute this in a separate terminal on PC2

docker run -d --network="my-net" --name couchdb1 -p 6984:5984 -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=adminpwd -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net hyperledger/fabric-couchdb

6. Peer 1
We will execute this in a separate terminal on PC2 to spawn peer1.

docker run -d --network="my-net" --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --name peer1.org1.example.com -p 9051:7051 -p 9053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpwd -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer1.org1.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer1.org1.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.example.com:7051 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051 -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_TLS_ENABLED=false -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start


7. CLI
Execute the below script in a different terminal on PC2 to spawn CLI.

docker run -it --rm --network="my-net" --name cli --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com -p 12051:7051 -p 12053:7053 -e GOPATH=/opt/gopath -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_TLS_ENABLED=false -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_ID=cli -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 -e CORE_PEER_NETWORKID=cli -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net  -v /var/run/:/host/var/run/ -v $(pwd)/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go -v $(pwd)/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ -v $(pwd)/scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-tools /bin/bash -c './scripts/script.sh'



If you see this, it means that the script has been executed


This will install the CLI container and will execute the script :

'./scripts/script.sh'
The script will:

Create channel; mychannel in our case
Make peer0 and peer1 join the channel.
Upon successful joining of the channel, the script will update the anchor peer (peer0 in our case).
Install the chaincode on both peers
Now our network is up and running, let’s test it out. Now we will invoke and query chaincode on both peers from PC2.

Let's do it

Testing the Network
Step 1. Bin/Bash CLI — PC2
We will again spawn the cli container on PC2, but this time we will exec into it

docker run --rm -it --network="my-net" --name cli --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com -p 12051:7051 -p 12053:7053 -e GOPATH=/opt/gopath -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_TLS_ENABLED=false -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_ID=cli -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 -e CORE_PEER_NETWORKID=cli -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net  -v /var/run/:/host/var/run/ -v $(pwd)/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go -v $(pwd)/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ -v $(pwd)/scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-tools /bin/bash
You must see this after executing the command.

root@a14d67c2dbb5:/opt/gopath/src/github.com/hyperledger/fabric/peer#
Now that you have entered into CLI container, we will execute the commands to instantiate, invoke and query the chaincode in this container.

Step 2. Instantiate Chaincode on Peer0
To instantiate the chaincode on peer0 we will need to set few environment variables first. Paste the below line in the cli terminal.

# Environment variables for PEER0

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
after that we will initialize chaincode. Execute the below command to instantiate the chaincode that was installed as a part of step 1.

$ peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"

This will instantiate the chiancode and populate it with a =100 and b = 200.

At this point, as your ledger is populated, you can view the transactions at (open it on browser on PC1)

Peer 0 (PC 1): http://localhost:5984/_utils/#/database/mychannel/_all_docs

Peer1 (PC 2): http://localhost:6984/_utils/#/database/mychannel/_all_docs

The above are the couchDB web interfaces endpoints. Since the data is saved in binary, you won’t find exact values(instead you will find hashes) but will see the records having key containing “myacc”.


OR
Let’s Query it and see the results. We will query it on peer1

Step 3. Query the Chaincode on Peer1
To query the chaincode on peer1 we will need to set few environment variables first. Paste the below line in the cli terminal on PC2

# Environment variables for PEER1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer1.org1.example.com:7051
Let’s query for the value of a to make sure the chaincode was properly instantiated and the couch DB was populated. The syntax for query is as follows: (execute in cli terminal) and wait for a while

$ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
it will bring

Query Result: 100
Step 4. Invoke the Chaincode on Peer0
To invoke the chaincode on peer0 we will need to set few environment variables first. Paste the below line in the cli terminal on PC2

# Environment variables for PEER0
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
Now let’s move 10 from a to b. This transaction will cut a new block and update the couch DB. The syntax for invoke is as follows: (execute in cli terminal on PC2)

$ peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}'
Step 5. Query the Chaincode
Let’s confirm that our previous invocation executed properly. We initialized the key a with a value of 100 and just removed 10 with our previous invocation. Therefore, a query against a should reveal 90. The syntax for query is as follows. (we are querying on peer0 so no need to change the environment variables)

# be sure to set the -C and -n flags appropriately
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
We should see the following:

Query Result: 90
Feel free to start over and manipulate the key value pairs and subsequent invocations.



UPDATE!!!!!!!!


# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx



docker run -d --network="my-net" --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --name peer1.org1.example.com -p 9051:7051 -p 9053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpwd -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer1.org1.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer1.org1.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.example.com:7051 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051 -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_TLS_ENABLED=false -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start




docker exec -it cli bash



docker run -d
--network="my-net"
--name ca.example.com
-p 7054:7054
-e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
-e FABRIC_CA_SERVER_CA_NAME=ca.example.com
-e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem
-e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/cb04eb7d8a26a7a6ae98f4b5672f4da2177b969ad033ecf1dc4891a3e8b12bfc_sk
-v $(pwd)/crypto-config/peerOrganizations/org1.example.com/ca/:/etc/hyperledger/fabric-ca-server-config
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hyp-net hyperledger/fabric-ca sh -c 'fabric-ca-server start -b admin:adminpw -d'


docker run -d --network="my-net"
--name orderer.example.com -p 7050:7050
-e ORDERER_GENERAL_LOGLEVEL=debug
-e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
-e ORDERER_GENERAL_LISTENPORT=7050
-e ORDERER_GENERAL_GENESISMETHOD=file
-e ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
-e ORDERER_GENERAL_LOCALMSPID=OrdererMSP
-e ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
-e ORDERER_GENERAL_TLS_ENABLED=false
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net
-v $(pwd)/channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
-v $(pwd)/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
-w /opt/gopath/src/github.com/hyperledger/fabric hyperledger/fabric-orderer orderer




docker run -d --link orderer.example.com:orderer.example.com
--network="my-net" --name peer0.org1.example.com -p 8051:7051 -p 8053:7053
-e CORE_LEDGER_STATE_STATEDATABASE=CouchDB
-e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984
-e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
-e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpwd
-e CORE_PEER_ADDRESSAUTODETECT=true
-e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
-e CORE_LOGGING_LEVEL=DEBUG
-e CORE_PEER_NETWORKID=peer0.org1.example.com
-e CORE_NEXT=true
-e CORE_PEER_ENDORSER_ENABLED=true
-e CORE_PEER_ID=peer0.org1.example.com
-e CORE_PEER_PROFILE_ENABLED=true
-e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050
-e CORE_PEER_GOSSIP_IGNORESECURITY=true
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net
-e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051
-e CORE_PEER_TLS_ENABLED=false
-e CORE_PEER_GOSSIP_USELEADERELECTION=false
-e CORE_PEER_GOSSIP_ORGLEADER=true
 -e CORE_PEER_LOCALMSPID=Org1MSP
 -v /var/run/:/host/var/run/
 -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp
 -w /opt/gopath/src/github.com/hyperledger/fabric/peer
 hyperledger/fabric-peer peer node start


docker run -d --network="my-net"
--link orderer.example.com:orderer.example.com
--link peer0.org1.example.com:peer0.org1.example.com
--name peer1.org1.example.com -p 9051:7051 -p 9053:7053
-e CORE_LEDGER_STATE_STATEDATABASE=CouchDB
-e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1:5984
-e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
-e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpwd
e CORE_PEER_ADDRESSAUTODETECT=true
-e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
-e CORE_LOGGING_LEVEL=DEBUG
-e CORE_PEER_NETWORKID=peer1.org1.example.com
-e CORE_NEXT=true
-e CORE_PEER_ENDORSER_ENABLED=true
-e CORE_PEER_ID=peer1.org1.example.com
-e CORE_PEER_PROFILE_ENABLED=true
-e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050
-e CORE_PEER_GOSSIP_ORGLEADER=true
-e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.example.com:7051
-e CORE_PEER_GOSSIP_IGNORESECURITY=true
-e CORE_PEER_LOCALMSPID=Org1MSP
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net
-e CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051
-e CORE_PEER_GOSSIP_USELEADERELECTION=false
-e CORE_PEER_TLS_ENABLED=false -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start
