pragma solidity ^0.4.17;

library MyLib {

    struct Sink {
      address spender;
      string name;
    }

    struct User {
      address myAddress;
      string name;
    }
    struct Agent {
      User u;
      uint[] budget;
      uint weight;
    }

    struct Coalition {
      uint[] current;
      uint[] listOfAgents;
    }
}
