pragma solidity ^0.4.24;

contract ColorEnum {

  enum Color {RED,ORANGE,YELLOW, GREEN}
  Color color;
  function construct() public {
     color = Color.RED;
  }
  function setColor(uint _value) public {
      color = Color(_value);
  }

  function getColor() public view returns (uint){
      return uint(color);
  }
    struct  person  {
         uint age;
         string fName;
         string lName;
    }
    uint amount =0;
    function buy() public payable{
        amount += msg.value;
    }

}