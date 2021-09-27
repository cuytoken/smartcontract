const cuyToken = artifacts.require("cuyToken");

module.exports = async function (deployer, network, accounts) {
  let name = "CuyToken";
  let symbol = "CTK";
  let initialAccount = accounts[0];
  let initialBalance = 0;

  await deployer.deploy(cuyToken, name, symbol, initialAccount, initialBalance);
};
