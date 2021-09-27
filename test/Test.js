let CuyToken = artifacts.require("./cuyToken.sol");

require("chai").use(require("chai-as-promised")).should();

contract("cuyToken", (accounts) => {
  let accountOwner, Alice, Bob, Carlos, Damian, Evert;

  beforeEach(async () => {
    cuyToken = await CuyToken.deployed();
    accountOwner = accounts[0];
    Alice = accounts[1];
    Bob = accounts[2];
    Carlos = accounts[3];
    Damian = accounts[4];
    Evert = accounts[5];
  });

  describe("Desplegando el contrato: ", async () => {
    let name = "CuyToken";
    let symbol = "CTK";
    let initialBalance = 0;
    let decimals = 18;
    // tokenSummary = TokenSummary(_initialAccount, _name, _symbol, 18);
    it("Recupera nombre del Token ", async () => {
      let name_ = await cuyToken.tokenSummary();
      expect(name_.name).to.be.eq(name);
      name_ = await cuyToken.name();
      expect(name_).to.be.eq(name);
    });

    it("Recupera símbolo del Token ", async () => {
      let symbol_ = await cuyToken.tokenSummary();
      expect(symbol_.symbol).to.be.eq(symbol);
      symbol_ = await cuyToken.symbol();
      expect(symbol_).to.be.eq(symbol);
    });

    it("Recupera # decimales del Token ", async () => {
      let dec = await cuyToken.tokenSummary();
      expect(Number(dec.decimals.toString())).to.be.eq(decimals);
      dec = await cuyToken.decimals();
      expect(Number(dec)).to.be.eq(decimals);
    });

    it("Recupera address que publicó el contrato ", async () => {
      let owner = await cuyToken.tokenSummary();
      expect(owner.initialAccount).to.be.eq(accountOwner);
    });

    it("Recupera suministro total al lanzamiento ", async () => {
      let supply = await cuyToken.totalSupply();
      expect(supply.toString()).to.be.eq(String(initialBalance));
    });
  });

  describe("MINADO, PRÉSTAMO y PAGO DE PRÉSTAMO ", () => {
    it("testing ", async () => {
      expect(true).to.be.eq(true);
    });
  });
});
