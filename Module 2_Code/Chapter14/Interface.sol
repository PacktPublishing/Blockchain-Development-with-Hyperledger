pragma solidity ^0.4.24;

contract A {
    function doSomething() public returns (string);
}
contract B is A {
    function doSomething() public returns (string) {
        return "Hello";
    }
}