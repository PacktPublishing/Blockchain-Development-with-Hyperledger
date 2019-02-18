pragma solidity ^0.4.24;

contract Modifiers {
	address public admin;
    function construct () public {
       admin = msg.sender;
    }
    //define the modifiers
    modifier onlyAdmin() {
        // if a condition is not met then throw an exception
        if (msg.sender != admin) revert();
        // or else just continue executing the function
        _;
    }
    // apply modifiers
    function kill() onlyAdmin public { 
    	selfdestruct(admin);
    }
}