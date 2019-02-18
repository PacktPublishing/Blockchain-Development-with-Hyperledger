pragma solidity ^0.4.24;

contract Ownable {
    address owner;
    uint public initTime = now;
    constructor() public {
      owner = msg.sender;
    }
    //check if the caller is the owner of the contract
    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner Allowed." );
         _;
    } 
    //change the owner of the contract
    //@param _newOwner the address of the new owner of the contract.
    function changeOwner(address _newOwner)  public onlyOwner  {
        owner = _newOwner;
    }
    function getOwner() internal constant returns (address) {
        return owner;
    }
    modifier onlyAfter(uint _time) {
        require(now >= _time,"Function called too early.");
        _;
    }
    modifier costs(uint _amount) {
        require(msg.value >= _amount,"Not enough Ether provided." );
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value - _amount);
    }
}
contract SampleContarct is Ownable {

    mapping(bytes32 => uint) myStorage;
    constructor() public {
    }
    function getValue(bytes32 record) constant public returns (uint) {
        return myStorage[record];
    }
    function setValue(bytes32 record, uint value)  public onlyOwner {
        myStorage[record] = value;
    }
    function forceOwnerChange(address _newOwner) public payable onlyOwner onlyAfter(initTime + 6 weeks) costs(50 ether) {
        owner =_newOwner;
        initTime = now;
    }
}