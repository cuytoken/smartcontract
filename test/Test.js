const truffleAssert = require("truffle-assertions");
require("chai").use(require("chai-as-promised")).should();

let CuyToken = artifacts.require("./cuyToken.sol");

contract("Pausable", (accounts) => {
  let accountOwner, Alice, Bob, Carlos, Damian, Evert;
  accountOwner = accounts[0];
  Alice = accounts[1];
  Bob = accounts[2];

  beforeEach(async () => {
    cuyToken = await CuyToken.deployed();
  });

  it("Funciones 'pause' y 'unpause' son solo llamadas por 'onlyOwner'", async () => {
    await truffleAssert.reverts(
      cuyToken.pause({ from: Alice }),
      "Only an owner account could make this call."
    );

    await truffleAssert.reverts(
      cuyToken.unpause({ from: Bob }),
      "Only an owner account could make this call."
    );
  });

  it("Funciones 'pause' y 'unpause' disparan eventos", async () => {
    let eventTriggered;

    eventTriggered = "PausedEvt";
    let tx1 = await cuyToken.pause({ from: accountOwner });
    expect(tx1.logs[0].event).to.be.eq(eventTriggered);
    expect(tx1.logs[0].args.account).to.be.eq(accountOwner);

    eventTriggered = "UnpausedEvt";
    let tx2 = await cuyToken.unpause({ from: accountOwner });
    expect(tx2.logs[0].event).to.be.eq(eventTriggered);
    expect(tx2.logs[0].args.account).to.be.eq(accountOwner);
  });
});

contract("cuyToken", (accounts) => {
  let accountOwner, Alice, Bob, Carlos, Damian, Evert;
  accountOwner = accounts[0];
  Alice = accounts[1];
  Bob = accounts[2];
  Carlos = accounts[3];
  Damian = accounts[4];
  Evert = accounts[5];
  let zero_address = "0x0000000000000000000000000000000000000000";

  beforeEach(async () => {
    cuyToken = await CuyToken.deployed();
  });

  xdescribe("Desplegando el contrato: ", async () => {
    let name = "CuyToken";
    let symbol = "CTK";
    let initialBalance = 0;
    let decimals = 18;

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
    // Datos del que recibirá el préstamo (loan)
    let account = Alice;
    let idClient = String(Math.floor(Math.random() * 10000)); // número de 5 dígitos
    let idBusiness = String(Math.floor(Math.random() * 10000)); // número de 5 dígitos
    let amountCuy = 30000;
    let amountFiat = 10000;
    let interest = 100;

    it("Función 'lend': solo es llamado por un 'onlyAdmin'. Muestra apropiado mensaje.", async () => {
      await truffleAssert.reverts(
        cuyToken.lend(
          account,
          idClient,
          idBusiness,
          amountCuy,
          amountFiat,
          interest,
          { from: Bob }
        ),
        "Only an Admin account could make this call."
      );
    });

    it("Función 'lend': solo es llamado cuando 'whenNotPaused' is True.", async () => {
      cuyToken = await CuyToken.deployed();
      await cuyToken.pause({ from: accountOwner });
      await truffleAssert.reverts(
        cuyToken.lend(
          Alice,
          idClient,
          idBusiness,
          amountCuy,
          amountFiat,
          interest,
          { from: accountOwner }
        ),
        "Contract is paused and cannot execute any operation."
      );
      await cuyToken.unpause({ from: accountOwner });
      let res = await cuyToken.lend(
        Alice,
        idClient,
        idBusiness,
        amountCuy,
        amountFiat,
        interest,
        { from: accountOwner }
      );
      expect(!!res).to.be.eq(true);
    });

    it("Función 'lend': cuenta del prestatario no debe ser 0x00...0", async () => {
      account = zero_address;
      await truffleAssert.reverts(
        cuyToken.lend(
          account,
          idClient,
          idBusiness,
          amountCuy,
          amountFiat,
          interest,
          { from: accountOwner }
        ),
        "Address account borrower must not be 0."
      );
    });
  });
});
