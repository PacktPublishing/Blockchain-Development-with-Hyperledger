pragma solidity ^0.4.24;

contract Animal {
    constructor() public {
    }
    function name() public returns (string) {
        return  "Animal";
    }
    function color() public returns (string);
}
contract Mammal is Animal {
    int size;
    constructor() public {
    }
    function name() public returns (string) {
        return  "Mammal";
    }
    function run() public pure returns (int) {
        return 10;
    }
    function color() public returns (string);
}
contract Dog is Mammal {
     function name() public returns (string) {
        return  "Dog";
    }  
    function color() public returns (string) {
        return "black";
    }
}