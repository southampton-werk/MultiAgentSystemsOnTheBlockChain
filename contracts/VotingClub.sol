pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";
import "./RegistrationClub.sol";
contract VotingClub is RegistrationClub {

    uint public termLength;
    uint public numberOfRepresentatives;
    MyLib.Agent[] listOfRepresentatives;

      uint[] candidates;
  address[][] votes;
  bool public voteStarted = false;
  uint public timeVoteStarted =0;
  uint public timeVoteEnded =0;
  uint votingTime = 0;
  uint weightingOption;
    function VotingClub(uint cost, uint term, uint reps, uint option) RegistrationClub(cost) public {
        termLength = term;
        numberOfRepresentatives = reps;
        weightingOption = option;
  }


    function apply() public {
      if(!isRegistered(msg.sender,buildCandidateList()))
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

  function startVote() public {
    if(timeVoteEnded + termLength < block.timestamp && voteStarted == false)
    {
      voteStarted = true;
      timeVoteStarted = block.timestamp;
    }
  }
  function vote(address[] myVote) public {
    for (uint i = 0; i < registeredUser.length; i++)
    {
      if(registeredUser[i].myAddress == msg.sender)
      {
        if(voteStarted == true && registeredUser[i].voted == false){
          registeredUser[i].voted = true;
          votes.push(myVote);
        }
      }
    }

  }
  function endVote() public
  {

    if(timeVoteStarted + votingTime <= block.timestamp && voteStarted == true)
    {
      voteStarted = false;
      timeVoteEnded = block.timestamp;
      if(candidates.length < numberOfRepresentatives)
      {
        numberOfRepresentatives = candidates.length;
      }

      countVotes();

      candidates.length = 0;
      votes.length = 0;

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


    //because candidates save int instead of user have to save sorted and unsorted and then compare
    uint[] memory ranked = new uint[](copelandScore.length);
    uint[] memory sortedSecondOrderCopeland = sort(secondOrderCopeland);

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

  function sort(uint[] data) returns (uint[]) {

    uint n = data.length;
    uint[] memory arr = new uint[](n);
    uint i;

    for(i=0; i<n; i++) {
      arr[i] = data[i];
    }

    uint[] memory stack = new uint[](n+2);

    //Push initial lower and higher bound
    uint top = 1;
    stack[top] = 0;
    top = top + 1;
    stack[top] = n-1;

    //Keep popping from stack while is not empty
    while (top > 0) {

      uint h = stack[top];
      top = top - 1;
      uint l = stack[top];
      top = top - 1;

      i = l;
      uint x = arr[h];

      for(uint j=l; j<h; j++){
        if  (arr[j] >= x) {
          //Move smaller element
          (arr[i], arr[j]) = (arr[j],arr[i]);
          i = i + 1;
        }
      }
      (arr[i], arr[h]) = (arr[h],arr[i]);
      uint p = i;

      //Push left side to stack
      if (p > l + 1) {
        top = top + 1;
        stack[top] = l;
        top = top + 1;
        stack[top] = p - 1;
      }

      //Push right side to stack
      if (p+1 < h) {
        top = top + 1;
        stack[top] = p + 1;
        top = top + 1;
        stack[top] = h;
      }
    }

    return arr;
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
    uint weightingOptionMemory = weightingOption;
    for (uint i = 0; i < numberOfRepresentatives; i++)
    {
      MyLib.Agent memory a;
      a.u = candidates[ranked[i]];
      if(weightingOptionMemory == 0)
      {
        a.weight = 1;
      }
      else if(weightingOptionMemory == 1)
      {
        a.weight = numberOfRepresentatives - i;
      }
      listOfRepresentatives.push(a);
    }
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

    function showVotes(uint number) public constant returns(address[])
    {
      return votes[number];
    }


}
