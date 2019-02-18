pragma solidity ^0.4.24;

contract Purchase {
    event buyEvent(address bidder, uint amount); // Event

    function buy() public payable {
        emit buyEvent(msg.sender, msg.value); // Triggering event
    }
}