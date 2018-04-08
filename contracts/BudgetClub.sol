pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;
import "./MyLib.sol";
import "./VotingClub.sol";
contract BudgetClub is VotingClub {
    uint public numberOfSinks;
      uint public quota;
  uint public gasCost;
  uint public numberOfTurns;
  uint public coalitionSizeFactor;
  uint public coalitionSizeFactorIncrease;

    MyLib.Sink[] listOfSinks;
    uint[] public finalBudget;

    function BudgetClub(uint cost, uint term, uint reps, uint sinks, uint q, uint gas, uint turns, uint sizeFactor, uint sizeFactorIncrease) VotingClub(cost,term,reps) public {
        numberOfSinks = sinks;
        quota = q;
        gasCost = gas;
        numberOfTurns = turns;
        coalitionSizeFactor = sizeFactor;
        coalitionSizeFactorIncrease = sizeFactorIncrease;
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
      uint quotaMemory = quota;
      uint numberOfRepresentativesMemory = numberOfRepresentatives;
      uint[][] memory coalitionBudgets = new uint[][](numberOfRepresentativesMemory);
      uint[] memory coalitionSize = new uint[](numberOfRepresentativesMemory);
      uint[] memory playerToCoalition = new uint[](numberOfRepresentativesMemory);
      MyLib.Agent[] memory playerToAgent = new MyLib.Agent[](numberOfRepresentativesMemory);
      uint i;
      //init
      for (i = 0; i < numberOfRepresentativesMemory; i++)
      {
        playerToAgent[i] = listOfRepresentatives[i];
        coalitionBudgets[i] =  playerToAgent[i].budget;
        coalitionSize[i] = 1;
        playerToCoalition[i] = i;
      }

      uint player = 0;
      while(winningCoalition(playerToCoalition,numberOfRepresentativesMemory,playerToAgent) == numberOfRepresentativesMemory)
      {
        //get utility in the current coalition
        uint[] memory bestOffer = new uint[](2);
        uint bestCoalition = numberOfRepresentativesMemory;
        uint myAfloor = afloor(coalitionBudgets[playerToCoalition[player]],playerToAgent[player].budget,coalitionSize[playerToCoalition[player]],quotaMemory);
        for(i = 0; i < numberOfRepresentativesMemory; i ++)
        {
          //dont check coalitions with no one or the one your in
          if(playerToCoalition[player] != i && coalitionSize[i] != 0)
          {
            uint[] memory nego = offer(coalitionBudgets[i],playerToAgent[player].budget,myAfloor,coalitionSize[i],playerToAgent[player].weight);
            if(nego[0] > bestOffer[0])
            {
              bestOffer = nego;
              bestCoalition = i;
            }
          }

        }

        if(bestCoalition != numberOfRepresentativesMemory)
        {
          coalitionBudgets[bestCoalition] = negoToBudget(playerToAgent[player].budget, coalitionBudgets[bestCoalition], bestOffer, coalitionSize[bestCoalition] + playerToAgent[player].weight);
          coalitionSize[playerToCoalition[player]] -= playerToAgent[player].weight;
          coalitionSize[bestCoalition] += playerToAgent[player].weight;
          playerToCoalition[player] = bestCoalition;

        }

        if(player == numberOfRepresentativesMemory - 1)
        {
          player = 0;
        }
        else{
          player ++;
        }
        coalitionSizeFactor += coalitionSizeFactorIncrease;

      }

      finalBudget = coalitionBudgets[winningCoalition(playerToCoalition,numberOfRepresentativesMemory,playerToAgent)];

    }

    function offer(uint[] budgetCoal, uint[] budgeta, uint myAfloor, uint coalSize, uint agentWeight) constant internal returns (uint[])
    {
      uint quotaMemory = quota;
      uint myAbar = abar(coalSize, agentWeight, quotaMemory);
      uint myBbar = bbar(budgeta, budgetCoal, coalSize, agentWeight, quotaMemory);
      uint myBfloor = bfloor(coalSize, quotaMemory);
      if(myAfloor + myBfloor < myAbar + myBbar)
      {
        return negotiate(myAbar, myBbar ,myAfloor, myBfloor);
      }
      else{
        return new uint[](2);
      }
    }

    function afloor(uint[] budgetCoala, uint[] budgeta, uint coalSizea, uint quotaMemory ) constant internal returns (uint)
    {
      return calculateUtility(budgetCoala,budgeta,coalSizea,quotaMemory);
    }
    function bfloor(uint coalSize,  uint quotaMemory) constant internal returns (uint)
    {
      return calculate100Utility(coalSize,quotaMemory);
    }
    function abar(uint coalSize, uint agentWeight,  uint quotaMemory) constant internal returns (uint)
    {
      return calculate100Utility(coalSize + agentWeight,quotaMemory);
    }
    function bbar(uint[] budgetCoal, uint[] budgeta, uint coalSize, uint agentWeight,  uint quotaMemory) constant internal returns (uint)
    {
      return calculateUtility(budgetCoal,budgeta,coalSize + agentWeight,quotaMemory);
    }
    function winningCoalition(uint[] playerToCoalition, uint numberOfRepresentativesMemory,MyLib.Agent[] playerToAgent ) constant internal returns (uint)
    {
      uint[] memory weights = new uint[](numberOfRepresentativesMemory);
      //add all the weights
      for (uint i = 0; i < numberOfRepresentativesMemory ; i++)
      {
        weights[playerToCoalition[i]] += playerToAgent[i].weight;
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

    function calculate100Utility(uint coalitionSize,  uint quotaMemory) constant internal returns (uint)
    {
      return (uint) ((coalitionSizeFactor * 100) / (quotaMemory + 1 - coalitionSize) + ((100-coalitionSizeFactor) * 100));
    }

    function calculateUtility(uint[] budget1,uint[] budget2, uint coalitionSize,  uint quotaMemory) constant internal returns (uint)
    {

      uint shared = sharedBudget(budget1,budget2);
      return (uint) ((coalitionSizeFactor * shared) / (quotaMemory + 1 - coalitionSize) + ((100-coalitionSizeFactor) * shared));
    }

    function sharedBudget(uint[] budget1,uint[] budget2) constant internal returns (uint)
    {
      uint shared = 0;
      for(uint i = 0; i < budget1.length; i ++)
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
      uint gasCostMemory = gasCost;
      uint usefulTurn = ((a_bar + b_bar - a_floor - b_floor - 2) / gasCostMemory) + 1;
      uint[] memory proposal = new uint[](2);

      uint numberOfTurnsMemory = numberOfTurns;
      if(usefulTurn > numberOfTurnsMemory)
      {
        usefulTurn = numberOfTurnsMemory;

      }
      uint freeUtility = a_bar + b_bar - ((usefulTurn - 1) * gasCostMemory) - a_floor - b_floor - 2;
      if(usefulTurn % 2 == 0)
      {
        proposal[1] = b_floor + 1 + freeUtility + (((usefulTurn/ 2)-1) * gasCostMemory) + 1;
        proposal[0] = a_bar + b_bar -  proposal[1];
      }
      else
      {
        proposal[0] = a_floor + 1 + freeUtility +  ((((usefulTurn + 1)/ 2)-1) * gasCostMemory);
        proposal[1] = a_bar + b_bar -  proposal[0];
      }
      //cant go over the best amount
      if(proposal[0] > a_bar)
      {
        proposal[1] +=  proposal[0] - a_bar;
        proposal[0] = a_bar;
      }
      else if(proposal[1] > a_bar)
      {
        proposal[0] +=  proposal[1] - a_bar;
        proposal[1] = a_bar;
      }


      return proposal;



    }

    function negoToBudget(uint[] budget1, uint [] budget2, uint[] nego, uint coalitionSize) constant public returns (uint[])
    {
      uint[] memory newBudget = new uint[](budget1.length);

      uint sharedab = sharedBudget(budget1,budget2);

      uint quotaMemory = quota;
      uint individuala = (uint) (nego[0] / ((coalitionSizeFactor / (quotaMemory + 1 - coalitionSize)) + (100 - coalitionSizeFactor)) - sharedab);
      uint individualb = (uint) (nego[1] / ((coalitionSizeFactor / (quotaMemory + 1 - coalitionSize)) + (100 - coalitionSizeFactor))- sharedab);


      uint suma = 0;
      uint sumb = 0;

      for(uint i = 0; i < budget1.length; i ++)
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
      for(i = 0; i < budget1.length; i ++)
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
        if(z == budget1.length - 1)
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

      function listSinks(uint number) public constant returns (string,address) {

      return (listOfSinks[number].name, listOfSinks[number].spender);
    }

      function getSinksLength() public constant returns (uint)
    {
      return listOfSinks.length;
    }

      function listFinalBudget(uint number) public constant returns(uint)
    {
      return finalBudget[number];
    }


}
