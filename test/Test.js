const truffleAssert = require("truffle-assertions");
require("chai").use(require("chai-as-promised")).should();

let CuyToken = artifacts.require("./cuyToken.sol");

const LOAN_PAID_ERROR = "CLIENTE_HAS_NO_LOAN_TO_PAY";
const LOAN_NOT_PAID_ERROR = "CLIENT_HAS_AN_UNPAID_LOAN";
const LOAN_PAID_CODE = 0;
const LOAN_NOT_PAID_CODE = 1;

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
  Fucci = accounts[6];
  seventhAccount = accounts[7];
  eighthAccount = accounts[8];
  ninethAccount = accounts[9];
  tenthAccount = accounts[10];
  eleventhAccount = accounts[11];

  let name = "CuyToken";
  let symbol = "CTK";
  let initialBalance = 0;
  let decimals = 18;
  let zero_address = "0x0000000000000000000000000000000000000000";
  let cuyToken;

  beforeEach(async () => {
    cuyToken = await CuyToken.deployed();
  });

  xdescribe("DESPLEGANDO el contrato: ", async () => {
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
      try {
        await cuyToken.lend(
          zero_address,
          idClient,
          idBusiness,
          amountCuy,
          amountFiat,
          interest,
          { from: accountOwner }
        );
      } catch (error) {
        expect(error.message).to.include("error");
      }
    });

    it("Función 'lend': cuenta del prestatario   debe ser 0x00...0. Muestra mensaje apropiado.", async () => {
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

    // Tokens minados se dirigen a un 'onlyAdmin'
    it("Function 'lend': Suministro Total se incrementa correctamente ", async () => {
      cuyToken = await CuyToken.deployed();
      account = Damian;
      amountCuy = 123123;
      amountFiat = 10000;
      interest = 100;
      let bsupply = await cuyToken.totalSupply();
      let totalSupply = Number(bsupply) + amountCuy;

      let lendTx = await cuyToken.lend(
        account,
        idClient,
        idBusiness,
        amountCuy,
        amountFiat,
        interest,
        { from: accountOwner }
      );

      let supply = await cuyToken.totalSupply();
      expect(supply.toString()).to.be.eq(String(totalSupply));
    });

    it("Función 'lend': Eventos 'Transfer' (de f()mint) y 'Lend' (de ()lend) son disparados correctamente", async () => {
      account = seventhAccount;
      amountCuy = 123123;
      amountFiat = 10000;
      interest = 100;

      let lendTx = await cuyToken.lend(
        account,
        idClient,
        idBusiness,
        amountCuy,
        amountFiat,
        interest,
        { from: accountOwner }
      );

      // Event 'Transfer'
      let evTransferName = "Transfer";
      let evTransfer = [...lendTx.logs].filter(
        (ev) => ev.event == evTransferName
      );

      assert.equal(
        evTransfer[0].event,
        evTransferName,
        "Name event does not match."
      );
      assert.equal(
        evTransfer[0].args._from,
        zero_address,
        "Is not sent from a address(0)."
      );
      assert.equal(
        evTransfer[0].args._to,
        accountOwner,
        "Transfer - Account target ('onlyAdmin') does not match."
      );
      assert.equal(
        evTransfer[0].args._value.toString(),
        amountCuy,
        "Amout of tokens sent does not match"
      );

      // Event 'Lend'
      let evLendName = "Lend";
      let evLend = [...lendTx.logs].filter((ev) => ev.event == evLendName);
      assert.equal(evLend[0].event, evLendName, "Event name does not match.");
      assert.equal(
        evLend[0].args.from,
        account,
        "Account target does not match."
      );
      assert.equal(
        evLend[0].args.value.toString(),
        amountCuy,
        "Amount of tokens sent does not match."
      );
    });

    it("Function 'lend': un prestatario no puede pedir otro préstamo hasta que cancele el que tiene", async () => {
      account = eighthAccount;
      amountCuy = 123123;
      amountFiat = 10000;
      interest = 100;

      await cuyToken.lend(
        account,
        idClient,
        idBusiness,
        amountCuy,
        amountFiat,
        interest,
        { from: accountOwner }
      );

      let currentSupply = await cuyToken.totalSupply();

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
        LOAN_NOT_PAID_ERROR
      );

      let afterSupply = await cuyToken.totalSupply();

      assert.equal(
        currentSupply.toString(),
        afterSupply.toString(),
        "Supply should not increase if user is not allowed to get another loan"
      );
    });

    it("Function 'lend': Verifica info del prestatario con 'loanBalance': ", async () => {
      account = Fucci;
      idClient = "FUCCI";
      idBusiness = "FUCCIBIZ";
      amountCuy = 321321;
      amountFiat = 10000;
      interest = 1000 + 100;

      let lendTx = await cuyToken.lend(
        account,
        idClient,
        idBusiness,
        amountCuy,
        amountFiat,
        interest,
        { from: accountOwner }
      );

      let balance = await cuyToken.loanBalance(account);
      let {
        scc,
        idClient: idClient_,
        idBusiness: idBusiness_,
        amountCuy: amountCuy_,
        amountFiat: amountFiat_,
        interest: interest_,
        interestFiat: interestFiat_,
        balanceFiat: balanceFiat_,
        balanceCuy,
        open,
      } = balance;
      expect(scc).to.be.eq(accountOwner);
      expect(idClient_).to.be.eq(idClient);
      expect(idBusiness_).to.be.eq(idBusiness);
      expect(amountCuy_).to.be.eq(String(amountCuy));
      expect(amountFiat_).to.be.eq(String(amountFiat));
      expect(interest_).to.be.eq(String(interest));
      expect(balanceCuy).to.be.eq(String(amountCuy));
    });
  });
});
