package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type ClaimContract struct {
}

// ============================================================================================================================
// define Insuree struct
// ============================================================================================================================
type Insuree struct {
	Id           string `json:"id"`
	FirstName    string `json:"firstName"`
	LastName     string `json:"lastName"`
	SSN          string `json:"ssn"`
	PolicyNumber string `json:"policyNumber"`
}

// ============================================================================================================================
// define company struct
// ============================================================================================================================
type Company struct {
	Id   string `json:"id"`
	Type string `json:"type"`
	Name string `json:"name"`
}

// ============================================================================================================================
// define claim struct
// ============================================================================================================================
type Claim struct {
	Id        string `json:"id"`        //the fieldtags are needed to keep case from bouncing around
	Desc      string `json:"desc"`      //claim description
	Status    string `json:"status"`    //status of claim
	InsureeId string `json:"insureeId"` //InsureeId
	BrokerId  string `json:"brokerId"`  //BrokerId
	InsurerId string `json:"insurerId"` //InsurerId
	Comment   string `json:"comment"`   //comment
	ProcessAt string `json:"processAt"` //processAt
}

func (c *ClaimContract) Init(stub shim.ChaincodeStubInterface) pb.Response {
	args := stub.GetStringArgs()
	if len(args) != 5 {
		return shim.Error("Incorrect arguments. Expecting a key and a value")
	}
	insureeId := args[0]
	firstName := args[1]
	lastName := args[2]
	ssn := args[3]
	policyNumber := args[4]
	insureeData := Insuree{
		Id:           insureeId,
		FirstName:    firstName,
		LastName:     lastName,
		SSN:          ssn,
		PolicyNumber: policyNumber}
	insureeBytes, _ := json.Marshal(insureeData)
	err := stub.PutState(insureeId, insureeBytes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to create asset: %s", args[0]))
	}
	return shim.Success(nil)
}

// ============================================================================================================================
// Dynamic Invoke insuance claim function
// ============================================================================================================================
func (c *ClaimContract) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "AddCompany" {
		return c.AddCompany(stub, args)
	} else if function == "ReportLost" {
		return c.ReportLost(stub, args)
	} else if function == "RequestedInfo" {
		return c.RequestedInfo(stub, args)
	} else if function == "SubmitClaim" {
		return c.SubmitClaim(stub, args)
	} else if function == "ConfirmClaimSubmission" {
		return c.ConfirmClaimSubmission(stub, args)
	} else if function == "ApproveClaim" {
		return c.ApproveClaim(stub, args)
	} else if function == "query" {
		return c.query(stub, args)
	} else if function == "getHistory" {
		return c.getHistory(stub, args)
	}

	return shim.Error("Invalid function name")
}

// ============================================================================================================================
// Insuree reprot the lost
// ============================================================================================================================
func (c *ClaimContract) ReportLost(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	claimId := args[0]
	desc := args[1]
	insureeId := args[2]
	brokerId := args[3]
	currentts := time.Now()
	processAt := currentts.Format("2006-01-02 15:04:05")
	//initialized claim
	claimData := Claim{
		Id:        claimId,
		Desc:      desc,
		Status:    "ReportLost",
		InsureeId: insureeId,
		BrokerId:  brokerId,
		InsurerId: "",
		Comment:   "",
		ProcessAt: processAt}
	claimBytes, _ := json.Marshal(claimData)
	stub.PutState(claimId, claimBytes)
	return shim.Success(claimBytes)
}

// ============================================================================================================================
// Broker return requested Information
// ============================================================================================================================
func (c *ClaimContract) RequestedInfo(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return c.UpdateClaim(stub, args, "RequestedInfo")
}

// ============================================================================================================================
//  Broker submit a claim to insurer
// ============================================================================================================================
func (c *ClaimContract) SubmitClaim(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return c.UpdateClaim(stub, args, "SubmitClaim")
}

// ============================================================================================================================
// insurer confirm get broker submission
// ============================================================================================================================
func (c *ClaimContract) ConfirmClaimSubmission(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return c.UpdateClaim(stub, args, "ConfirmClaimSubmission")
}

// ============================================================================================================================
// insurer approval claim
// ============================================================================================================================
func (c *ClaimContract) ApproveClaim(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return c.UpdateClaim(stub, args, "ApproveClaim")
}

// ============================================================================================================================
// update Claim data in blockchain
// ============================================================================================================================
func (c *ClaimContract) UpdateClaim(stub shim.ChaincodeStubInterface, args []string, currentStatus string) pb.Response {
	claimId := args[0]
	comment := args[1]
	claimBytes, err := stub.GetState(claimId)
	claim := Claim{}
	err = json.Unmarshal(claimBytes, &claim)
	if err != nil {
		return shim.Error(err.Error())
	}
	if currentStatus == "RequestedInfo" && claim.Status != "ReportLost" {
		claim.Status = "Error"
		fmt.Printf("Claim is not initialized yet")
		return shim.Error(err.Error())
	} else if currentStatus == "SubmitClaim" && claim.Status != "RequestedInfo" {
		claim.Status = "Error"
		fmt.Printf("Claim must be in RequestedInfo status")
		return shim.Error(err.Error())
	} else if currentStatus == "ConfirmClaimSubmission" && claim.Status != "SubmitClaim" {
		claim.Status = "Error"
		fmt.Printf("Claim must be in Submit Claim status")
		return shim.Error(err.Error())
	} else if currentStatus == "ApproveClaim" && claim.Status != "ConfirmClaimSubmission" {
		claim.Status = "Error"
		fmt.Printf("Claim must be in Confirm Claim Submission status")
		return shim.Error(err.Error())
	}
	claim.Comment = comment
	if currentStatus == "RequestedInfo" {
		insurerId := args[2]
		claim.InsurerId = insurerId
	}
	currentts := time.Now()
	claim.ProcessAt = currentts.Format("2006-01-02 15:04:05")
	claim.Status = currentStatus
	claimBytes0, _ := json.Marshal(claim)
	err = stub.PutState(claimId, claimBytes0)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(claimBytes0)
}

// ============================================================================================================================
// Add Company data in blockchain
// ============================================================================================================================

func (c *ClaimContract) AddCompany(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	id := args[0]
	name := args[1]
	companyType := args[2]
	companyData := Company{
		Id:   id,
		Type: companyType,
		Name: name}
	companyBytes, _ := json.Marshal(companyData)
	stub.PutState(id, companyBytes)
	return shim.Success(companyBytes)
}

// ============================================================================================================================
// Get Claim Data By Query Claim By ID
//
// ============================================================================================================================
func (c *ClaimContract) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var ENIITY string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expected ENIITY Name")
	}

	ENIITY = args[0]
	Avalbytes, err := stub.GetState(ENIITY)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + ENIITY + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil order for " + ENIITY + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(Avalbytes)
}

// ============================================================================================================================
// Get history of asset
//
// Shows Off GetHistoryForKey() - reading complete history of a key/value
//
// ============================================================================================================================
func (c *ClaimContract) getHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	type AuditHistory struct {
		TxId  string `json:"txId"`
		Value Claim  `json:"value"`
	}
	var history []AuditHistory
	var claim Claim

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	claimId := args[0]
	fmt.Printf("- start getHistoryForClaim: %s\n", claimId)

	// Get History
	resultsIterator, err := stub.GetHistoryForKey(claimId)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	for resultsIterator.HasNext() {
		historyData, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}

		var tx AuditHistory
		tx.TxId = historyData.TxId
		json.Unmarshal(historyData.Value, &claim)
		tx.Value = claim              //copy claim over
		history = append(history, tx) //add this tx to the list
	}
	fmt.Printf("- getHistoryForClaim returning:\n%s", history)

	//change to array of bytes
	historyAsBytes, _ := json.Marshal(history) //convert to array of bytes
	return shim.Success(historyAsBytes)
}
func main() {

	err := shim.Start(new(ClaimContract))
	if err != nil {
		fmt.Printf("Error creating new Insuance Claim Contract: %s", err)
	}
}
