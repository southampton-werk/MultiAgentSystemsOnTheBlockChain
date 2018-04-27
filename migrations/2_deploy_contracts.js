var Club = artifacts.require("BudgetClub");
var MyLib = artifacts.require("MyLib");


module.exports = function(deployer) {
  deployer.deploy(MyLib);
  deployer.deploy(Club,500,1000,7,0,2,4,1,100,80,1);
};
