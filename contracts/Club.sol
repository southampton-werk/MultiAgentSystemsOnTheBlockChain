pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";

contract Club {

  uint public numberOfRepresentatives;
  uint public numberOfSinks;
  uint public registrationCost;
  uint public termLength;
  MyLib.User[] registeredUser;
  MyLib.User[] candidates;
  address[][] votes;
  mapping (address => bool) public voted;
  bool public voteStarted = false;
  uint public timeVoteStarted =0;
  uint public timeVoteEnded =0;
  bool public budgetSubmit = false;
  uint public timeBudgetStarted =0;
  uint[] public secondOrderCopelandUnsorted;
  MyLib.Agent[] listOfRepresentatives;
  MyLib.Sink[] listOfSinks;
  uint[] public finalBudget;

  //this should be memory but i have to store it here for some reason
  mapping (uint => uint[]) defeated;
  mapping (uint => uint[]) currentCoalitions;
  mapping (uint => uint[]) coalitionBudgets;


  function Club(uint reps, uint sinks, uint cost, uint term) public {
    numberOfRepresentatives = reps;
    numberOfSinks = sinks;
    registrationCost = cost;
    termLength = term;
  }


  function startVote() public {
    if(timeVoteEnded + termLength < block.timestamp && voteStarted == false)
    {
      voteStarted = true;
      timeVoteStarted = block.timestamp;
    }
  }

  function vote(address[] myVote) public {
    if(isRegistered() && voteStarted == true && voted[msg.sender] == false){
      voted[msg.sender] = true;
      votes.push(myVote);

    }
  }
  function endVote() public
  {
    if(timeVoteStarted <= block.timestamp && voteStarted == true)
    {
      voteStarted = false;
      timeVoteEnded = block.timestamp;
      countVotes();
    }

  }
  //second order copeland
  function countVotes() internal {
    //stack was full
    uint i;
    uint p;
    uint[] memory copelandScore = new uint[](candidates.length);

    //pairwise each candidate against each other
    for (i = 0; i < candidates.length - 1; i++)
    {
      for (p = 1 + i; p < candidates.length; p++)
      {
          uint pairwise = pairwiseComparison(i,p);
          if(pairwise == 0)
          {
            defeated[i].push(p);
            copelandScore[i] ++;
          }
          else if (pairwise == 1) {
            defeated[p].push(i);
            copelandScore[p] ++;
          }
      }
    }
    //add up the copeland scores of defeated users
    uint[] memory secondOrderCopeland = new uint[](candidates.length);
    for(i =0; i < copelandScore.length; i++)
    {
      for(p = 0; p < defeated[i].length; p++)
      {
        secondOrderCopeland[i] += copelandScore[defeated[i][p]];
      }
      //remove all from defeated
      defeated[i].length = 0;

    }
    secondOrderCopelandUnsorted = secondOrderCopeland;
}
  function pairwiseComparison(uint i, uint p) internal constant returns (uint)
  {
    uint scorei = 0;
    uint scorep = 0;
    for(uint z =0; z < votes.length; z ++)
    {
      if (scorei < votes.length / 2 && scorep < votes.length /2)
      {
        //if not seen its the highest
        uint ilocation = votes[z].length;
        uint plocation = votes[z].length;
        for(uint j =0; j < votes[z].length; j ++)
        {

          if(votes[z][j] == candidates[i].myAddress )
          {
            ilocation = j;
          }
          else if(votes[z][j] == candidates[p].myAddress )
          {
            plocation = j;
          }
        }
        if(ilocation < plocation)
        {
          scorei ++;
        }
        else if(plocation > ilocation)
        {
          scorep ++;
        }
      }
      else{
        //if majority for one candidate no need to continue
        break;
      }
    }
    if(scorei > scorep)
    {
      return 0;
    }
    else if (scorep > scorei) {
      return 1;
    }
    else
    {
      return 2;
    }
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
    //saves gass as dont have to look at candidates with no votes
    function apply() public {
      if(!addressUsed(msg.sender,candidates))
      {
        for (uint i = 0; i < registeredUser.length; i++)
        {
          if(registeredUser[i].myAddress == msg.sender)
          {
            candidates.push(registeredUser[i]);
          }
        }
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

    function sortedCopeland(uint[] secondOrderCopelandSorted) internal constant returns(bool)
    {
      uint lastSeen = secondOrderCopelandUnsorted[secondOrderCopelandSorted[0]];
      for (uint i = 1; i < secondOrderCopelandUnsorted.length; i++)
      {
        if(lastSeen < secondOrderCopelandUnsorted[secondOrderCopelandSorted[i]])
        {
          return false;
        }
      }
      return true;
    }

    function weightCandidates(uint[] secondOrderCopelandSorted) public
    {

      if(sortedCopeland(secondOrderCopelandSorted))
      {
        for (uint i = 0; i < numberOfRepresentatives; i++)
        {
          MyLib.Agent memory a;
          a.u = candidates[secondOrderCopelandSorted[i]];
          a.weight = 1;
          listOfRepresentatives.push(a);
        }
        secondOrderCopelandUnsorted.length = 0;
        candidates.length = 0;
        budgetSubmit = true;
        timeBudgetStarted = block.timestamp;
      }
    }

    function submitBudget(uint[] budget) public
    {
      for (uint i = 0; i < numberOfRepresentatives; i++)
      {
        if(listOfRepresentatives[i].u.myAddress == msg.sender)
        {
          listOfRepresentatives[i].budget = budget;
        }
      }
    }
    //who should be able to do this
    function submitSink(address spender, string name) public
    {
      MyLib.Sink memory s;
      s.name = name;
      s.spender = spender;
      listOfSinks.push(s);
    }

    //
    function endBudgetSumbit() public
    {
      if(timeBudgetStarted <= block.timestamp && budgetSubmit == true)
      {
        budgetSubmit = false;
        decideBudget();
      }
    }

    function decideBudget() internal {

      //init coalitions, everyone in their own coalition
      for (uint i = 0; i < numberOfRepresentatives; i++)
      {
        currentCoalitions[i].push(i);
        coalitionBudgets[i] = listOfRepresentatives[i].budget;
      }


    }



    function listRegisteredUsers(uint number) public constant returns (string,address) {

      return (registeredUser[number].name, registeredUser[number].myAddress);
    }

    function getRegisteredUsersLength() public constant returns (uint)
    {
      return registeredUser.length;
    }

    function listCandidates(uint number) public constant returns (string,address) {

      return (candidates[number].name, candidates[number].myAddress);
    }

    function getCandidatesLength() public constant returns (uint)
    {
      return candidates.length;
    }

    function listRepresentives(uint number) public constant returns (string,address,uint,uint[]) {

      return (listOfRepresentatives[number].u.name, listOfRepresentatives[number].u.myAddress, listOfRepresentatives[number].weight,listOfRepresentatives[number].budget);
    }

    function getRepresentivesLength() public constant returns (uint)
    {
      return listOfRepresentatives.length;
    }

    function listSinks(uint number) public constant returns (string,address) {

      return (listOfSinks[number].name, listOfSinks[number].spender);
    }

    function getSinksLength() public constant returns (uint)
    {
      return listOfSinks.length;
    }

    function showVotes(uint number) public constant returns(address[])
    {
      return votes[number];
    }


    function showUnsortedCopeland() public constant returns(uint[])
    {
      return secondOrderCopelandUnsorted;
    }









  }
