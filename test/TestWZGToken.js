

var WizzleGlobalToken = artifacts.require("WizzleGlobalToken");

contract('WizzleGlobalToken', function(accounts) {

  it("init totalSupply zero", function() {
	var inst;
    return WizzleGlobalToken.deployed().then(function(instance) {
		inst = instance;
		return inst.totalSupply.call();
    }).then(function(ts) {
      assert.equal(ts.valueOf(), 0, "initial totalSupply = 0");
    });
  });
  
  it("totalSuppy and balance after transaction", function(instance){
    var inst;
    return WizzleGlobalToken.deployed().then(function(instance){
        inst = instance;
        return inst.mint()
    });

  });
  
  /*
  it("should be bigger", function(){
	  var ins;
	  return Storage.deployed().then(function(inst){
		  ins = inst;
		  return ins.setTime({from: accounts[0]});
	  }).then(function(){
		  return ins.getTime.call();
	  }).then(function(val){
		  assert.isAtLeast(new Date(), val, "should be bigger");
	  });
	  
  });
  */

});