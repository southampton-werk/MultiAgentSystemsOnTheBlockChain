pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";
contract RegistrationClub {

  MyLib.User[] registeredUser;
  uint public registrationCost;
  mapping(uint => uint) registrationCostSuggestions;

  function RegistrationClub(uint cost) public {
    registrationCost = cost;

  }

  function register(string name) public payable {
    if (msg.value >= registrationCost && (!isRegistered(msg.sender,registeredUser)) ) {
      MyLib.User memory u;
      u.myAddress = msg.sender;
      u.name = name;
      registeredUser.push(u);
    }
    //initlisate suggestions as registrationCost
    registrationCostSuggestions[registeredUser.length  - 1] = registrationCost;
  }


  function isRegistered(address sample, MyLib.User[] userList) internal pure returns (bool)
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

  function changeRegistrationCostSuggestion(uint suggestion) public {
    for (uint i = 0; i < registeredUser.length; i++)
    {
      if(registeredUser[i].myAddress == msg.sender)
      {
        registrationCostSuggestions[i] = suggestion;
      }
    }
  }

  function changeRegistrationCost() public {
    uint suggestion = checkRegistrationSuggestions();
    if(suggestion != registrationCost)
    {
      registrationCost = suggestion;
    }
  }

  function checkRegistrationSuggestions() constant public returns (uint) {
    if(registeredUser.length > 1)
    {
      uint superMajority = ((registeredUser.length * 2) / 3) + 1  ;
      for (uint i = 0; i < registeredUser.length; i++)
      {
        uint count = 0;
        uint iSuggestion = registrationCostSuggestions[i];
        for (uint p = 0; p < registeredUser.length; p++)
        {
          if(iSuggestion == registrationCostSuggestions[p])
          {
            count ++;
          }
        }
        if (count >= superMajority)
        {
          return iSuggestion;
        }
      }
    }
      return registrationCost;
  }
  function subsidize() public payable {}



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
