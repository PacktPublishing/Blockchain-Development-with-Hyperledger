pragma solidity ^0.4.24;

contract StudentScore {
    
    struct Student {
        uint score;
        string name;
    }
    
    mapping (address => Student) studtents;
    address[] public studentAccts;
    
    function setStudent(address _address, uint _score, string _name) public {
        Student storage studtent = studtents[_address];
        studtent.score = _score;
        studtent.name = _name;
        studentAccts.push(_address) -1;
    }
    
    function getStudents() view public returns(address[]) {
        return studentAccts;
    }
    
    function getStudent(address _address) view public returns (uint, string) {
        return (studtents[_address].score, studtents[_address].name);
    }
    
    function countStudents() view public returns (uint) {
        return studentAccts.length;
    }
    
}