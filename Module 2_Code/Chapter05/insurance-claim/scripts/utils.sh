#
# # Blockchain Quick Start Guide - Insuance Claim
# Utility script for run peer command
#
# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ic.com/orderers/orderer.ic.com/msp/tlscacerts/tlsca.ic.com-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ic.com/users/Admin@ic.com/msp
}
# PEER0 for Insuree
# PEER1 for Broker
# PEER2 for Insurer
setGlobals () {
	ORG=$2
	if [ $ORG -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ic.com/peers/peer0.org1.ic.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ic.com/users/Admin@org1.ic.com/msp
		#Insuree
		if [ $1 -eq 0 ]; then
			#Insuree
			CORE_PEER_ADDRESS=peer0.org1.ic.com:7051
			PEER=PEER0
		fi
	elif [ $ORG -eq 2 ] ; then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.ic.com/peers/peer0.org2.ic.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.ic.com/users/Admin@org2.ic.com/msp
		#Broker
		if [ $1 -eq 0 ]; then
			#Broker
			CORE_PEER_ADDRESS=peer0.org2.ic.com:7051
			PEER=PEER1
		fi
	elif [ $ORG -eq 3 ] ; then
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.ic.com/peers/peer0.org3.ic.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.ic.com/users/Admin@org3.ic.com/msp
		#Insurer
		if [ $1 -eq 0 ]; then
			#Insurer
			CORE_PEER_ADDRESS=peer0.org3.ic.com:7051
			PEER=PEER2
		fi		
	else
		echo "================== ERROR !!! ORG OR PEER Unknown =================="
	fi

	env |grep CORE
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannelWithRetry $PEER $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

createChannel() {
	setGlobals 0 1

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.ic.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
	else
		peer channel create -o orderer.ic.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "Channel \"$CHANNEL_NAME\" is created successfully."
	echo
	echo
}
installChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	peer chaincode install -n iccc -v 1.0 -l ${LANGUAGE} -p github.com/chaincode/claimcontract >&log.txt
	res=$?
	cat log.txt
	verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
	echo "===================== Chaincode is installed on remote peer${PEER}.org${ORG} ===================== "
	echo
}
updateAnchorPeersWithRetry() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	peer channel update -f ./channel-artifacts/Org${ORG}MSPanchors.tx -c $CHANNEL_NAME -o orderer.ic.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to update Anchor in channel, Retry after $DELAY seconds"
		sleep $DELAY
		updateAnchorPeersWithRetry $PEER $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to update anchor in  the Channel"
	
}
instantiateChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG

	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer chaincode instantiate -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -l ${LANGUAGE} -v 1.0 -c '{"Args":["user_001","John","Smith", "9999","4394497111/1"]}' -P "OR	('Org1MSP.member','Org2MSP.member','Org3MSP.member')" >&log.txt
		res=$?
                set +x
	else
                set -x
		peer chaincode instantiate -o orderer.ic.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -l ${LANGUAGE} -v 1.0 -c '{"Args":["user_001","John","Smith", "9999","4394497111/1"]}' -P "OR	('Org1MSP.member','Org2MSP.member','Org3MSP.member')" >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}
#query claim
chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  echo "========== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ======= "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n iccc -c '{"Args":["query","claim_001"]}' >&log.txt
  done
  echo
  cat log.txt
}
chaincodeQueryUser () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  echo "========== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ======= "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n iccc -c '{"Args":["query","user_001"]}' >&log.txt
  done
  echo
  cat log.txt
}

#Add Broker
chaincodeInvokeAddBroker() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["AddCompany","broker_001","BROKER","BNC Brokerage"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["AddCompany","broker_001","BROKER","BNC Brokerage"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:AddBroker execution on PEER$PEER failed "
	echo "Invoke:AddBroker transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}
#Add Insurer
chaincodeInvokeAddInsurer() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["AddCompany","insurer_001","INSURER","Western Insurance"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["AddCompany","insurer_001","INSURER","Western Insurance"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:AddInsurer execution on PEER$PEER failed "
	echo "Invoke:AddInsurer transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}
#call Invoke Report Lost by invoke chaincode
chaincodeInvokeReportLost() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["ReportLost","claim_001", "I was in Destiny shopping center and lost my IPhone 8", "user_001", "broker_001"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["ReportLost","claim_001", "I was in Destiny shopping center and lost my IPhone 8", "user_001", "broker_001"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:ReportLost execution on PEER$PEER failed "
	echo "Invoke:ReportLost transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}

#call Invoke Requested Info by invoke chaincode
chaincodeInvokeRequestedInfo() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["RequestedInfo","claim_001", "Broker processsed user John Smith report and sent Requested Info to user.", "insurer_001"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["RequestedInfo","claim_001", "Broker processsed user John Smith report and sent Requested Info to user.", "insurer_001"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:RequestedInfo execution on PEER$PEER failed "
	echo "Invoke:RequestedInfo transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}

#call Invoke Submit Claim by invoke chaincode
chaincodeInvokeSubmitClaim () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["SubmitClaim","claim_001", "Broker submitted a claim"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["SubmitClaim","claim_001", "Broker submitted a claim"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:SubmitClaim execution on PEER$PEER failed "
	echo "Invoke:SubmitClaim transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}

#call Invoke Confirm Claim Submission by invoke chaincode
chaincodeInvokeConfirmClaimSubmission () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["ConfirmClaimSubmission","claim_001", "Insurer received and confirmed a claim"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["ConfirmClaimSubmission","claim_001", "Insurer received and confirmed a claim"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:ConfirmClaimSubmission execution on PEER$PEER failed "
	echo "Invoke:ConfirmClaimSubmission transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}
#call Invoke Approve Claim by invoke chaincode
chaincodeInvokeApproveClaim () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.ic.com:7050 -C $CHANNEL_NAME -n iccc -c '{"Args":["ApproveClaim","claim_001", "Insurer processed and approved the claim."]}' >&log.txt
	else
		peer chaincode invoke -o orderer.ic.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n iccc -c '{"Args":["ApproveClaim","claim_001", "Insurer processsed and approved the claim."]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:ApproveClaim execution on PEER$PEER failed "
	echo "Invoke:ApproveClaim transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}
#query claim history
chaincodeQueryHistory() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  echo "========== History Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ======= "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n iccc -c '{"Args":["getHistory","claim_001"]}' >&log.txt
  done
  echo
  cat log.txt
}