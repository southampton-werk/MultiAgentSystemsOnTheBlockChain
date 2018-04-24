var BudgetClub = artifacts.require("BudgetClub");

contract('BudgetClub', function(accounts) {
  it("User registration", function() {
    return BudgetClub.deployed().then(function(instance) {
      return instance.register("jake",{value: 600,from: accounts[0]}).then(function() {
        return instance.getRegisteredUsersLength({from: accounts[0]}).then(function(userLength) {
          assert.equal(userLength, 1, "User added");
          return instance.register("hard",{value: 600,from: accounts[0]}).then(function() {
            return instance.getRegisteredUsersLength({from: accounts[0]}).then(function(userLength) {
              assert.equal(userLength, 1, "User address added twice");
              return instance.register("jake",{value: 2,from: accounts[0]}).then(function() {
                return instance.getRegisteredUsersLength({from: accounts[0]}).then(function(userLength) {
                  assert.equal(userLength, 1, "User hasnt send enough gas");
                });
              });
            });
          });
        });
      });
    });
  });
});
