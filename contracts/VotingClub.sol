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
  bool[] public voted;
  bool public voteStarted = false;
  uint public timeVoteStarted =0;
  uint public timeVoteEnded =0;
  uint votingTime = 0;
  uint weightingOption;
    function VotingClub(uint cost, uint term, uint reps) RegistrationClub(cost) public {
        termLength = term;
        numberOfRepresentatives = reps;
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
    for (uint i = 0; i < userList.length; i++)
    {
      if(registeredUser[i].myAddress == sample)
      {
        if(voteStarted == true && voted[i] == false){
          voted[i] = true;
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
