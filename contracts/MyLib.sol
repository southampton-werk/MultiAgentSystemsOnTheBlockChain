pragma solidity ^0.4.18;

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
      uint u;
      uint[] budget;
      uint weight;
    }

}
