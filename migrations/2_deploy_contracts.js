var Club = artifacts.require("Club");
var MyLib = artifacts.require("MyLib");
var Budget = artifacts.require("Budget");
var Vote = artifacts.require("Vote");



module.exports = function(deployer) {
  deployer.deploy(MyLib);
  deployer.deploy(Budget);
  deployer.deploy(Vote);
  deployer.deploy(Club,3,2,500,1000);
};
