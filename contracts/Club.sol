pragma solidity ^0.4.17;
import "./MyLib.sol";
import "./Vote.sol";

contract Club {

  MyLib.User[] registeredUser;
  uint public numberOfRepresentatives;
  uint public numberOfSinks;
  uint public registrationCost;
  uint public termLength;
  mapping (address => address) votes;
  mapping (address => uint) voteCount;
  MyLib.Agent[] listOfAgents;
  MyLib.Sink[] listOfSinks;

  function Club(uint reps, uint sinks, uint cost, uint term) public {
    numberOfRepresentatives = reps;
    numberOfSinks = sinks;
    registrationCost = cost;
    termLength = term;
  }

  function useVote(address a) public constant returns (uint) {
    Vote v = Vote(a);
    return v.return5();
  }


  function register(string name) public payable {
    if (msg.value > registrationCost) {
          MyLib.User memory u;
          u.myAddress = msg.sender;
          u.name = name;
          registeredUser.push(u);
    }
  }

  function listRegisteredUsers() public constant returns (string) {

        return registeredUser[0].name;

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

  function vote(address myVote) public {
    if(isRegistered()){
      votes[msg.sender] = myVote;

    }
  }

  function seeContractBalance() public constant returns (uint){
    return this.balance;
  }

}
