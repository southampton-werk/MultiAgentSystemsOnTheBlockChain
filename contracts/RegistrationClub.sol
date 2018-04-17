pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";
contract RegistrationClub {

  MyLib.User[] registeredUser;
  uint public registrationCost;

  function RegistrationClub(uint cost) public {
    registrationCost = cost;

  }

  function subsidize() public payable {}

    function isRegistered() public constant returns (bool) {
      for (uint i = 0; i < registeredUser.length; i++) {
        if(registeredUser[i].myAddress == msg.sender)
        {
          return true;
        }
      }
      return false;
    }


    function register(string name) public payable {
      if (msg.value > registrationCost && (!addressUsed(msg.sender,registeredUser)) ) {
        MyLib.User memory u;
        u.myAddress = msg.sender;
        u.name = name;
        registeredUser.push(u);
      }
    }


    function addressUsed(address sample, MyLib.User[] userList) internal pure returns (bool)
    {
      for (uint i = 0; i < userList.length; i++)
      {
        if(userList[i].myAddress == sample)
        {
          return true;
        }
      }
      return false;
    }

    event message(string message, string name);

    function chat(string text) public constant
    {
      for(uint i = 0; i < registeredUser.length; i ++)
      {
        if(registeredUser[i].myAddress == msg.sender)
        {
          message(text, registeredUser[i].name);
        }
      }
    }

    function sayhi() public constant
    {
      message("hi","jake");
    }



    function listRegisteredUsers(uint number) public constant returns (string,address) {

      return (registeredUser[number].name, registeredUser[number].myAddress);
    }

    function getRegisteredUsersLength() public constant returns (uint)
    {
      return registeredUser.length;
    }

    function getContractValue() public constant returns (uint)
    {
      return this.balance;
    }


  }
