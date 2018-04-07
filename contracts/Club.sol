pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";

contract Club {

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
  uint public numberOfRepresentatives;
  uint public numberOfSinks;
  uint public quota = 5;
  uint public gasCost = 1;
  uint public numberOfTurns = 100;
  uint public coalitionSizeFactor = 20;
  uint public coalitionSizeFactorIncrease = 1;


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
      if(copelandScore[i] != 0)
      {
        for(p =0; p < copelandScore[i] ; p++)
        {
          secondOrderCopeland[i] += copelandScore[defeated[i][p]];
        }
      }
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
          //stops same score being matched twice
          secondOrderCopeland[p] = copelandScore.length  * copelandScore.length;
          break;
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
    uint voteLength = votes.length;
    address iaddress = registeredUser[candidates[i]].myAddress;
    address paddress = registeredUser[candidates[p]].myAddress;

    for(uint z =0; z < voteLength; z ++)
    {
      if (scorei <= voteLength / 2 && scorep <= voteLength /2)
      {
        //if not seen its the highest
        uint votezlength = votes[z].length;
        for(uint j =0; j < votezlength; j ++)
        {
          address voteaddress = votes[z][j];
          if(voteaddress == iaddress )
          {
            scorei ++;
            break;
          }
          else if(voteaddress == paddress )
          {
            scorep ++;
            break;
          }
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
    quickSort(data, uint(0), uint(data.length - 1));
    return data;
  }

  function quickSort(uint[] memory arr, uint left, uint right) internal{
    uint i = left;
    uint j = right;
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
      uint candidatesLength = candidates.length;
      MyLib.User[] memory userList = new MyLib.User[](candidatesLength);
      for(uint i = 0; i < candidatesLength; i ++)
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


    function decideBudget() public
    {
      uint numberOfRepresentativesMemory = numberOfRepresentatives;
      uint[][] memory coalitionBudgets = new uint[][](numberOfRepresentativesMemory);
      uint[] memory coalitionSize = new uint[](numberOfRepresentativesMemory);
      uint[] memory playerToCoalition = new uint[](numberOfRepresentativesMemory);

      uint i;
      //init
      for (i = 0; i < numberOfRepresentativesMemory; i++)
      {
        coalitionBudgets[i] = listOfRepresentatives[i].budget;
        coalitionSize[i] = 1;
        playerToCoalition[i] = i;
      }

      uint round = 0;

      while(winningCoalition(playerToCoalition,numberOfRepresentativesMemory) == numberOfRepresentativesMemory)
      {
        uint player = round % numberOfRepresentativesMemory;
        MyLib.Agent memory agent = listOfRepresentatives[player];
        //get utility in the current coalition
        uint currentUtility = calculateUtility(coalitionBudgets[playerToCoalition[player]],agent.budget,coalitionSize[player]);
        uint[] memory bestOffer = new uint[](1);
        uint bestCoalition = numberOfRepresentativesMemory;

        for(i = 0; i < numberOfRepresentativesMemory; i ++)
        {
          //dont check coalitions with no one or the one your in
          if(playerToCoalition[player] != i && coalitionSize[i] != 0)
          {
            if(currentUtility +  calculate100Utility(coalitionSize[i]) < calculate100Utility(coalitionSize[i] + agent.weight) + calculateUtility(agent.budget, coalitionBudgets[i], coalitionSize[i] + agent.weight))
            {
              uint[] memory nego = negotiate(calculate100Utility(coalitionSize[i] + agent.weight), calculateUtility(agent.budget, coalitionBudgets[i], coalitionSize[i] + agent.weight),currentUtility, calculate100Utility(coalitionSize[i]));
              if(nego[0] > bestOffer[0])
              {
                bestOffer = nego;
                bestCoalition = i;
              }
            }

          }
        }

        if(bestCoalition != numberOfRepresentativesMemory)
        {
          coalitionBudgets[bestCoalition] = negoToBudget(agent.budget, coalitionBudgets[bestCoalition], bestOffer, coalitionSize[bestCoalition] + agent.weight);
          coalitionSize[playerToCoalition[player]] -= agent.weight;
          coalitionSize[bestCoalition] += agent.weight;
          playerToCoalition[player] = bestCoalition;

        }

        round ++;
        coalitionSizeFactor += coalitionSizeFactorIncrease;

      }

      finalBudget = coalitionBudgets[winningCoalition(playerToCoalition,numberOfRepresentativesMemory)];

    }

    function winningCoalition(uint[] playerToCoalition, uint numberOfRepresentativesMemory) constant internal returns (uint)
    {
      uint[] memory weights = new uint[](numberOfRepresentativesMemory);
      //add all the weights
      for (uint i = 0; i < numberOfRepresentativesMemory ; i++)
      {
        weights[playerToCoalition[i]] += listOfRepresentatives[i].weight;
      }
      for (i = 0; i < numberOfRepresentativesMemory ; i++)
      {
        if(weights[i] >= quota)
        {
          return i;
        }
      }
      return numberOfRepresentativesMemory;
    }

    function calculate100Utility(uint coalitionSize) constant internal returns (uint)
    {
      uint shared = 100;
      return (uint) ((coalitionSizeFactor * shared) / (quota + 1 - coalitionSize) + ((100-coalitionSizeFactor) * shared));
    }

    function calculateUtility(uint[] budget1,uint[] budget2, uint coalitionSize) constant internal returns (uint)
    {

      uint shared = sharedBudget(budget1,budget2);
      return (uint) ((coalitionSizeFactor * shared) / (quota + 1 - coalitionSize) + ((100-coalitionSizeFactor) * shared));
    }

    function sharedBudget(uint[] budget1,uint[] budget2) constant internal returns (uint)
    {
      uint shared = 0;
      for(uint i = 0; i < numberOfSinks; i ++)
      {
        if(budget1[i] > budget2[i])
        {
          shared += budget2[i];
        }
        else{
          shared += budget1[i];
        }
      }
      return shared;
    }
    function negotiate(uint a_bar,uint b_bar,uint a_floor,uint b_floor)constant  public returns (uint[])
    {

      uint usefulTurn = ((a_bar + b_bar - a_floor - b_floor - 2) / gasCost) + 1;
      uint a_proposal = 0;
      uint b_proposal = 0;


      if(usefulTurn > numberOfTurns)
      {
        usefulTurn = numberOfTurns;

      }
      uint freeUtility = a_bar + b_bar - ((usefulTurn - 1) * gasCost) - a_floor - b_floor - 2;
      if(usefulTurn % 2 == 0)
      {
        b_proposal = b_floor + 1 + freeUtility + (((usefulTurn/ 2)-1) * gasCost) + 1;
        a_proposal = a_bar + b_bar - b_proposal;
      }
      else
      {
        a_proposal = a_floor + 1 + freeUtility +  ((((usefulTurn + 1)/ 2)-1) * gasCost);
        b_proposal = a_bar + b_bar - a_proposal;
      }
      //cant go over the best amount
      if(a_proposal > a_bar)
      {
        b_proposal += a_proposal - a_bar;
        a_proposal = a_bar;
      }
      else if(b_proposal > a_bar)
      {
        a_proposal += b_proposal - a_bar;
        b_proposal = a_bar;
      }

      uint[] memory proposal = new uint[](2);
      proposal[0] = a_proposal;
      proposal[1] = b_proposal;
      return proposal;



    }

    function negoToBudget(uint[] budget1, uint [] budget2, uint[] nego, uint coalitionSize) constant public returns (uint[])
    {
      uint[] memory newBudget = new uint[](numberOfSinks);

      uint sharedab = sharedBudget(budget1,budget2);

      uint individuala = (uint) (nego[0] / ((coalitionSizeFactor / (quota + 1 - coalitionSize)) + (100 - coalitionSizeFactor)) - sharedab);
      uint individualb = (uint) (nego[1] / ((coalitionSizeFactor / (quota + 1 - coalitionSize)) + (100 - coalitionSizeFactor))- sharedab);

      uint suma = 0;
      uint sumb = 0;

      for(uint i = 0; i < numberOfSinks; i ++)
      {
        if(budget1[i] > budget2[i])
        {
          suma += budget1[i];
        }
        else{
          sumb += budget2[i];
        }
      }

      uint total = 0;
      for(i = 0; i < numberOfSinks; i ++)
      {
        if(budget1[i] > budget2[i])
        {
          total +=  budget2[i] + individuala * budget1[i] / suma;
          newBudget[i] = budget2[i] + individuala * budget1[i] / suma;
        }
        else{
          total +=  budget1[i] + individualb * budget2[i] / sumb;
          newBudget[i] = budget1[i] + individualb * budget2[i] / sumb;
        }
      }
      uint z = 0;
      while(total < 100)
      {
        newBudget[z] += 1;
        total +=1;
        if(z == numberOfSinks - 1)
        {
          z = 0;
        }
        else
        {
          z ++;
        }
      }


      return newBudget;
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

    function listFinalBudget(uint number) public constant returns(uint)
    {
      return finalBudget[number];
    }

  }
