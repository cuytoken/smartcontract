const cuyToken = artifacts.require("cuyToken");

module.exports = function (deployer, network, accounts) {
  let name = "CuyToken";
  let symbol = "CTK";
  let initialAccount = accounts[0];
  let initialBalance = 0;
  deployer.deploy(cuyToken, name, symbol, initialAccount, initialBalance);
};
