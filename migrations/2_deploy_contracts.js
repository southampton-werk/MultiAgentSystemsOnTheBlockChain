var Club = artifacts.require("BudgetClub");
var MyLib = artifacts.require("MyLib");


module.exports = function(deployer) {
  deployer.deploy(MyLib);
  deployer.deploy(Club,500,1000,5,3,5,1,100,20,1);
};
