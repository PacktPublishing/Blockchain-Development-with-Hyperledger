#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build Insurance Claim Network (ICN) end-to-end test"
echo
CHANNEL_NAME="icchannel"
DELAY="$2"
LANGUAGE="golang"
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="20"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ic.com/orderers/orderer.ic.com/msp/tlscacerts/tlsca.ic.com-cert.pem

CC_SRC_PATH="github.com/chaincode/claimcontract/"

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.ic.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
	else
		peer channel create -o orderer.ic.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2 3; do
		joinChannelWithRetry 0 $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	done
}

updateAnchorChannel () {
	for org in 1 2 3; do
		updateAnchorPeersWithRetry 0 $org
		echo "===================== Updates Anchor peer${peer}.org${org} on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

echo "Update Anchor ..."
updateAnchorChannel

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on Insuree peer: peer0.org1..."
installChaincode 0 1
echo "Installing chaincode on Broker peer: peer0.org2..."
installChaincode 0 2
echo "Installing chaincode on Insurer peer: peer0.org3..."
installChaincode 0 3

# Instantiate chaincode on peer0.org1
echo "Instantiating chaincode Add User (Insuree) transaction on peer0.org1..."
instantiateChaincode 0 1
chaincodeQueryUser 0 1

# Invoke chaincode add  Broker on peer0.org2
echo "Sending invoke Add Company (Broker) transaction on peer0.org2..."
chaincodeInvokeAddBroker 0 2

# Invoke chaincode add  insurer on peer0.org3
echo "Sending invoke Add Company (insurer) transaction on peer0.org3..."
chaincodeInvokeAddInsurer 0 3


# Invoke chaincode ReportLost on peer0.org1
echo "Sending invoke ReportLost transaction on peer0.org1..."
chaincodeInvokeReportLost 0 1

# Query chaincode on peer0.org1
echo "Querying chaincode Issuance Claim on peer0.org1..."
chaincodeQuery 0 1

# Invoke chaincode RequestedInfo on peer0.org2
echo "Sending invoke RequestedInfo transaction on peer0.org2..."
chaincodeInvokeRequestedInfo 0 2

# Query chaincode on peer0.org2
echo "Querying chaincode Issuance Claim on peer0.org2..."
chaincodeQuery 0 2

# Invoke chaincode SubmitClaim on peer0.org2
echo "Sending invoke SubmitClaim transaction on peer0.org2..."
chaincodeInvokeSubmitClaim 0 2

# Query chaincode on peer0.org2
echo "Querying chaincode Issuance Claim on peer0.org2..."
chaincodeQuery 0 2

# Invoke chaincode ConfirmClaimSubmission on peer0.org2
echo "Sending invoke ConfirmClaimSubmission transaction on peer0.org3..."
chaincodeInvokeConfirmClaimSubmission 0 3

# Query chaincode on peer0.org3
echo "Querying chaincode Issuance Claim on peer0.org3..."
chaincodeQuery 0 3

# Invoke chaincode ApproveClaim on peer0.org2
echo "Sending invoke ApproveClaim transaction on peer0.org1..."
chaincodeInvokeApproveClaim 0 1

# Query chaincode Issuance Claim on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery 0 1

# Query chaincode on peer0.org1
echo "Querying Claim History on peer0.org1..."
chaincodeQueryHistory 0 1

echo
echo "========= Insuance Claim End to End Test Completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
