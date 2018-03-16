#!/usr/bin/env bash

docker-compose -d up

docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx

# Join peer0.org1.example.com to the channel.
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" cli peer channel join -b mychannel.block