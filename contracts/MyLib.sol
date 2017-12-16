pragma solidity ^0.4.17;

library MyLib {

    struct Sink {
      address myAddress;
      string name;
    }

    struct Budget {
      uint[] budget;
    }

    struct User {
      address myAddress;
      string name;
    }
    struct Agent {
      User u;
      Budget myBudget;
      uint weight;
    }

    struct Coalition {
      Budget current;
      Agent[] listOfAgents;
    }
}
