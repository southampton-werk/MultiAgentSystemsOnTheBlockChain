pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";

contract Club {

  uint public numberOfRepresentatives;
  uint public numberOfSinks;
  uint public registrationCost;
  uint public termLength;
  MyLib.User[] registeredUser;
  uint[] candidates;
  address[][] votes;
  mapping (address => bool) public voted;
  bool public voteStarted = false;
  uint public timeVoteStarted =0;
  uint public timeVoteEnded =0;
  MyLib.Agent[] listOfRepresentatives;
  MyLib.Sink[] listOfSinks;
  uint[] public finalBudget;

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
    uint i;
    uint p;
    uint[] memory copelandScore = new uint[](candidates.length);
    uint[][] memory defeated = new uint[][](copelandScore.length);

    //init2d array
    for (i = 0; i < copelandScore.length; i++)
    {
      defeated[i] = new uint[](copelandScore.length);
    }

    //pairwise each candidate against each other
    for (i = 0; i < copelandScore.length - 1; i++)
    {
      for (p = 1 + i; p < copelandScore.length; p++)
      {
        uint pairwise = pairwiseComparison(i,p);
        if(pairwise == 0)
        {
          defeated[i][copelandScore[i]] = p;
          copelandScore[i] ++;
        }
        else if (pairwise == 1) {
          defeated[p][copelandScore[p]] = i;
          copelandScore[p] ++;
        }
      }
    }

    //add up the copeland scores of defeated users
    uint[] memory secondOrderCopeland = new uint[](copelandScore.length);
    for(i =0; i < copelandScore.length; i++)
    {
        secondOrderCopeland[i] = copelandScore[i];
    }

    uint[] memory ranked = new uint[](copelandScore.length);
    uint[] memory sortedSecondOrderCopeland = sort(copy(secondOrderCopeland));

    for(i=0; i < copelandScore.length; i ++ )
    {
      for(p=0; p < copelandScore.length; p ++ )
      {
        if(sortedSecondOrderCopeland[i] == secondOrderCopeland[p])
        {
          ranked[i] = p;
          secondOrderCopeland[p] = copelandScore.length  * copelandScore.length;
        }
      }
    }

    weightCandidates(ranked);

  }

  function copy(uint[] toCopy) internal pure returns (uint[])
  {
    uint[] memory copyTo = new uint[](toCopy.length);
    for(uint i = 0; i < toCopy.length; i ++)
    {
      copyTo[i] = toCopy[i];
    }
    return copyTo;
  }
  function pairwiseComparison(uint i, uint p) internal constant returns (uint)
  {
    uint scorei = 0;
    uint scorep = 0;
    for(uint z =0; z < votes.length; z ++)
    {
      if (scorei <= votes.length / 2 && scorep <= votes.length /2)
      {
        //if not seen its the highest
        uint ilocation = votes[z].length;
        uint plocation = votes[z].length;
        for(uint j =0; j < votes[z].length; j ++)
        {

          if(votes[z][j] == registeredUser[candidates[i]].myAddress )
          {
            ilocation = j;
          }
          else if(votes[z][j] == registeredUser[candidates[p]].myAddress )
          {
            plocation = j;
          }
        }
        if(ilocation < plocation)
        {
          scorei ++;
        }
        else if(plocation < ilocation)
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
  function weightCandidates(uint[] ranked) public
  {
    for (uint i = 0; i < numberOfRepresentatives; i++)
    {
      MyLib.Agent memory a;
      a.u = candidates[ranked[i]];
      a.weight = 1;
      listOfRepresentatives.push(a);
    }
    candidates.length = 0;

  }
  function sort(uint[] data) public returns (uint[]) {
    quickSort(data, int(0), int(data.length - 1));
    return data;
  }

  function quickSort(uint[] memory arr, int left, int right) internal{
    int i = left;
    int j = right;
    if(i==j) return;
    uint pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint(i)] > pivot) i++;
      while (pivot > arr[uint(j)]) j--;
      if (i <= j) {
        (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
        i++;
        j--;
      }
    }
    if (left < j)
    quickSort(arr, left, j);
    if (i < right)
    quickSort(arr, i, right);
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
      if(!addressUsed(msg.sender,buildCandidateList()))
      {
        for (uint i = 0; i < registeredUser.length; i++)
        {
          if(registeredUser[i].myAddress == msg.sender)
          {
            candidates.push(i);
          }
        }
      }
    }

    function buildCandidateList() internal constant returns (MyLib.User[])
    {
      MyLib.User[] memory userList = new MyLib.User[](candidates.length);
      for(uint i = 0; i < candidates.length; i ++)
      {
        userList[i] = registeredUser[candidates[i]];
      }
      return userList;
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

    function submitBudget(uint[] budget) public
    {
      for (uint i = 0; i < numberOfRepresentatives; i++)
      {
        if(registeredUser[listOfRepresentatives[i].u].myAddress == msg.sender)
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


    function endBudgetSumbit() public
    {
      if(timeVoteEnded <= block.timestamp && voteStarted == false)
      {
        decideBudget();
      }
    }

    function decideBudget() internal {

      uint[][] memory currentCoalitions = new uint[][](numberOfRepresentatives);
      uint[][] memory coalitionBudgets = new uint[][](numberOfRepresentatives);
      //init coalitions, everyone in their own coalition with their own budget
      for (uint i = 0; i < numberOfRepresentatives; i++)
      {
        currentCoalitions[i][0] = i;
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

      return (registeredUser[candidates[number]].name, registeredUser[candidates[number]].myAddress);
    }

    function getCandidatesLength() public constant returns (uint)
    {
      return candidates.length;
    }

    function listRepresentives(uint number) public constant returns (string,address,uint,uint[]) {

      return (registeredUser[listOfRepresentatives[number].u].name, registeredUser[listOfRepresentatives[number].u].myAddress, listOfRepresentatives[number].weight,listOfRepresentatives[number].budget);
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


  }
