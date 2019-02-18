pragma solidity ^0.4.24;

contract HelloWorld {
  string public greeting;

  constructor() public {
    greeting = 'Hello World';
  }

  function setNewGreeting (string _newGreeting) public {
    greeting = _newGreeting;
  }
}