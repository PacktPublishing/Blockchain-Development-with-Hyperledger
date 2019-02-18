pragma solidity ^0.4.24;

contract CrowdFunding {

    Project public project;
    Contribution[] public contributions;
    //Campaign Status
    enum Status {
        Fundraising,
        Fail,
        Successful
    }
    event LogProjectInitialized (
        address owner,
        string name,
        string website,
        uint minimumToRaise, 
        uint duration
    );
    event ProjectSubmitted(address addr, string name, string url, bool initialized);
    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogProjectPaid(address projectAddr, uint amount, Status status);
    event Refund(address _to, uint amount);
    event LogErr (address addr, uint amount);
    //campaign contributors
    struct Contribution {
        address addr;
        uint amount;
    }
    //define project
    struct Project {
        address addr;
        string name;
        string website;
        uint totalRaised;
        uint minimumToRaise; 
        uint currentBalance;
        uint deadline;
        uint completeAt;
        Status status;
    }
    //initialized project
    constructor (address _owner, uint _minimumToRaise, uint _durationProjects, 
        string _name, string _website) public payable {  
        uint minimumToRaise = _minimumToRaise * 1 ether; //convert to wei
        uint deadlineProjects = now + _durationProjects* 1 seconds;
        project = Project(_owner, _name, _website, 0, minimumToRaise, 0, deadlineProjects, 0, Status.Fundraising);
        emit LogProjectInitialized(
            _owner,
            _name,
            _website,
            _minimumToRaise,
            _durationProjects);
    }
    //check if project is at the required stage
    modifier atStage(Status _status) {
        require(project.status == _status,"Only matched status allowed." );
        _;
    }
    //check if msg.sender is project owner
    modifier onlyOwner() {
        require(project.addr == msg.sender,"Only Owner Allowed." );
        _;
    }
    //check if project pass the deadline
    modifier afterDeadline() {
        require(now >= project.deadline);
        _;
    }
    //Wait for 6 hour after campaign completed before allowing contract destruction
    modifier atEndOfCampain() {
        require(!((project.status == Status.Fail || project.status == Status.Successful) && project.completeAt + 6 hours < now));
        _;
    }
    function () public payable {
       revert();  
    }

    /* The default fallback function is called whenever anyone sends funds to a contract */
    function fund() public atStage(Status.Fundraising) payable {
        contributions.push(
            Contribution({
                addr: msg.sender,
                amount: msg.value
                })
            );
        project.totalRaised += msg.value;
        project.currentBalance = project.totalRaised;
        emit LogFundingReceived(msg.sender, msg.value, project.totalRaised);
    }
    //checks if the goal or time limit has been reached and ends the campaign
    function checkGoalReached() public onlyOwner afterDeadline {
        require(project.status != Status.Successful && project.status!=Status.Fail);
        if (project.totalRaised > project.minimumToRaise){
            project.addr.transfer(project.totalRaised);
            project.status = Status.Successful;
            emit LogProjectPaid(project.addr, project.totalRaised, project.status);
        } else {
            project.status = Status.Fail;
            for (uint i = 0; i < contributions.length; ++i) {
              uint amountToRefund = contributions[i].amount;
              contributions[i].amount = 0;
              if(!contributions[i].addr.send(contributions[i].amount)) {
                contributions[i].amount = amountToRefund;
                emit LogErr(contributions[i].addr, contributions[i].amount);
                revert();
              } else{
                project.totalRaised -= amountToRefund;
                project.currentBalance = project.totalRaised;
                emit Refund(contributions[i].addr, contributions[i].amount);
              }
            }  
        }
        project.completeAt = now;
    }
    function destroy() public onlyOwner atEndOfCampain {
        selfdestruct(msg.sender);
    }
}