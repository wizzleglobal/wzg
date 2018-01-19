
var WizzleGlobalToken = artifacts.require("WizzleGlobalToken");
var WizzleGlobalController = artifacts.require("WizzleGlobalController");

module.exports = function(deployer) {
  deployer.deploy(WizzleGlobalToken)
          .then(function() {
              return deployer.deploy(WizzleGlobalController, WizzleGlobalToken.address);
          }).then(function(){
              return WizzleGlobalController.changeController({from: accounts[0]});
          });
};