#!/usr/bin/env bash

docker-compose -f docker-compose-oneOrg.yml up -d

docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" cli peer channel join -b mychannel.block
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051"  cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051"  cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["invoke","a","b","20"]}'
docker exec -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" cli peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'