var tontine = artifacts.require("../src/tontine.sol");
// var runningTontine = artifacts.require("../src/runningtontine.sol")

module.exports = function(deployer) {
  deployer.deploy(tontine, 1533439190, 0.06, 0xCC10cA8708c93d19540Ad55A7De21FAcb62a4a75);
  // deployer.deploy(runningTontine);
};