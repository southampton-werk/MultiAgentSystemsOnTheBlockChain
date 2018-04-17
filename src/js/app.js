var votingOrder = [];
var budget = [];
var candidates = [];
App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // Is there an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('BudgetClub.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var ClubArtifact = data;
      App.contracts.Club = TruffleContract(ClubArtifact);

      // Set the provider for our contract
      App.contracts.Club.setProvider(App.web3Provider);

    });

  },


};

$(function() {
  $(window).load(function() {
    App.init();
  });
});


function refreshChat() {

  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      clubInstance.message().watch(function(error, result){
                   alert('hi');
               });
    })
  });

}

//get price
function register(name) {

  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.register(name, {value: 600, from: account});
    })
  });
}

function apply() {
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.apply({from: account});
    })
  });
}
function getUser(number)
{
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;

      clubInstance.listRegisteredUsers(number).then(function(value) {
        alert("a="+value[0]);
        alert("b="+value[1]);
      });

    })
  });
}



function outputAllUsers() {
  var cart=[];

  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }
    var account = accounts[0];
    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      clubInstance.getRegisteredUsersLength().then(function(size) {
        for(var i = 0; i < size; i++) {
          clubInstance.listRegisteredUsers(i).then(function(value) {
            var element = {};
            element.name = value[0];
            element.address = value[1];
            cart.push(element);
            var list = document.createElement('ul');

            for(var i = 0; i < cart.length; i++) {
              // Create the list item:
              var item = document.createElement('li');
              // Set its contents:
              item.appendChild(document.createTextNode(cart[i].name + " " + cart[i].address));

              // Add it to the list:
              list.appendChild(item);
            }

            // Finally, return the constructed list:
            while (document.getElementById('Users').firstChild) document.getElementById('Users').removeChild(document.getElementById('Users').firstChild);
            document.getElementById('Users').appendChild(list);

          });
        }
      });
    });
  });
}

function outputAllCandidates() {
  var candidateRow = $('#candidateRow');
  var candidateTemplate = $('#candidateTemplate');
  candidateRow.html("");
  candidates = [];
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }
    var account = accounts[0];
    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      clubInstance.getCandidatesLength().then(function(size) {
        for(var i = 0; i < size; i++) {
          clubInstance.listCandidates(i).then(function(value) {
            var element = {};
            element.name = value[0];
            element.address = value[1];
            candidates.push(element);
            candidateRow.html("");
            for(var i = 0; i < candidates.length; i++) {

              candidateTemplate.find('.btn-adopt').attr('name', i);
              candidateTemplate.find('.candidate-name').text(candidates[i].name);
              candidateTemplate.find('.candidate-address').text(candidates[i].address);

              candidateRow.append(candidateTemplate.html());

            }

          });
        }
      });
    });
  });



}

function rankVote(rank)
{
  votingOrder.push(candidates[rank].address);

  document.getElementById("order").value = "Current Voting Order: " + votingOrder;
}

function resetVote()
{
  votingOrder = [];
  document.getElementById("order").value = "Current Voting Order: " + votingOrder;
}

function submitVote()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.vote(votingOrder);
    })
  });
}

function startVote()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.startVote();
    })
  });
}

function endVote()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.endVote();
    })
  });
}

function refreshSettings()
{
  document.getElementById("currentTime").value = "Current Time: " + Math.round((new Date()).getTime() / 1000);
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      clubInstance.termLength().then(function(termLength) {

        document.getElementById("termLength").value = "Term Length: " + termLength;
      });
      clubInstance.getContractValue().then(function(contractValue) {

        document.getElementById("ContractValue").value = "Contract Value: " + contractValue;
      });
      clubInstance.numberOfRepresentatives().then(function(numberOfRepresentatives) {

        document.getElementById("numberOfRepresentatives").value = "Number of Repersentives: " + numberOfRepresentatives;
      });
      clubInstance.numberOfSinks().then(function(numberOfSinks) {

        document.getElementById("numberOfSinks").value = "Number of Sinks: " + numberOfSinks;
      });
      clubInstance.registrationCost().then(function(registrationCost) {

        document.getElementById("registrationCost").value = "Registration Cost: " + registrationCost;
      });
      clubInstance.voteStarted().then(function(voteStarted) {

        document.getElementById("voteStarted").value = "Vote Started: " + voteStarted;
      });
      clubInstance.timeVoteStarted().then(function(timeVoteStarted) {

        document.getElementById("timeVoteStarted").value = "Time Vote Started: " + timeVoteStarted;
      });
      clubInstance.timeVoteEnded().then(function(timeVoteEnded) {

        document.getElementById("timeVoteEnded").value = "Time Vote Ended: " + timeVoteEnded;
      });
      clubInstance.quota().then(function(quota) {
        document.getElementById("quota").value = "quota: " + quota;
      });
      clubInstance.gasCost().then(function(gasCost) {
        document.getElementById("gasCost").value = "Gas Cost: " + gasCost;
      });
      clubInstance.numberOfTurns().then(function(numberOfTurns) {
        document.getElementById("numberOfTurns").value = "Number Of Turns: " + numberOfTurns;
      });
      clubInstance.coalitionSizeFactor().then(function(coalitionSizeFactor) {
        document.getElementById("coalitionSizeFactor").value = "Coalition Size Factor: " + coalitionSizeFactor;
      });
      clubInstance.coalitionSizeFactorIncrease().then(function(coalitionSizeFactorIncrease) {
        document.getElementById("coalitionSizeFactorIncrease").value = "Coalition Size Factor Increase: " + coalitionSizeFactorIncrease;
      });

    })
  });
}

function decideBudget()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.decideBudget({from: account});
    })
  });
}
function addSink(address,name)
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.submitSink(address,name, {from: account});
    })
  });
}
function outputAllSinks()
{

  var cart=[];

  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }
    var account = accounts[0];
    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      clubInstance.getSinksLength().then(function(size) {
        for(var i = 0; i < size; i++) {
          clubInstance.listSinks(i).then(function(value) {
            var element = {};
            element.name = value[0];
            element.address = value[1];
            cart.push(element);
            var list = document.createElement('ul');

            for(var i = 0; i < cart.length; i++) {
              // Create the list item:
              var item = document.createElement('li');
              // Set its contents:
              item.appendChild(document.createTextNode(i + ": " + cart[i].name + " " + cart[i].address));

              // Add it to the list:
              list.appendChild(item);
            }

            // Finally, return the constructed list:
            while (document.getElementById('Sinks').firstChild) document.getElementById('Sinks').removeChild(document.getElementById('Sinks').firstChild);
            document.getElementById('Sinks').appendChild(list);

          });
        }
      });
    });
  });
}
function addBudget(budgetNumber)
{
  budget.push(budgetNumber);
  document.getElementById("CurrentBudget").value = "Current Budget: " + budget;
}
function resetBudget()
{
  budget = [];
  document.getElementById("CurrentBudget").value = "Current Budget: " + budget;
}
function submitBudget()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.submitBudget(budget);
    })
  });
}

function sendOut()
{
  var clubInstance;
  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];

    App.contracts.Club.deployed().then(function(instance) {
      clubInstance = instance;
      return clubInstance.sendOut({from: account});
    })
  });
}
