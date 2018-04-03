var Club = artifacts.require("Club");
var MyLib = artifacts.require("MyLib");



module.exports = function(deployer) {
  deployer.deploy(MyLib);
  deployer.deploy(Club,3,2,500,1000);
};
