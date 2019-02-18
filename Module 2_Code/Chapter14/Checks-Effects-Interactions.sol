pragma solidity ^0.4.24;

contract Fund {
    mapping(address => uint) userBalances;
    function withdrawBalance() public {
         uint amt = userBalances[msg.sender];
         userBalances[msg.sender] =0;
         msg.sender.transfer(amt);
    }
}