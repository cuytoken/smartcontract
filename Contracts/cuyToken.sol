// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 *@notice The cuytoken implements the ERC20 token
 *@author Lenin Tarrillo
 */

/**
 * Define owner, transfer owner and assign admin
 */
contract Owned {
    address private _owner;
    string public constant NO_OWNER_ERROR =
        "THE_ACCOUNT_IS_NOT_OWNER_OF_THE_CONTRACT";
    string public constant NO_ADMIN_ERROR =
        "THE_ACCOUNT_IS_NOT_ADMIN_OF_THE_CONTRACT";

    mapping(address => bool) admins;

    constructor() {
        _owner = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, NO_OWNER_ERROR);
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender] == true, NO_ADMIN_ERROR);
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function isAdmin(address account) public view onlyOwner returns (bool) {
        return admins[account];
    }

    function addAdmin(address account) public onlyOwner {
        require(account != address(0) && !admins[account]);
        admins[account] = true;
    }

    function removeAdmin(address account) public onlyOwner {
        require(account != address(0) && admins[account]);
        admins[account] = false;
    }
}

/**
 * The purpose of CriptoCredit contract is manage Lending system
 * add debtors and the information of the loan that is granted to them
 */
contract CriptoCredit is Owned {
    mapping(address => LoanInfo) debtors;

    string public constant LOAN_PAID_ERROR = "CLIENTE_HAS_NO_LOAN_TO_PAY";
    string public constant LOAN_NOT_PAID_ERROR = "CLIENT_HAS_AN_UNPAID_LOAN";
    string public constant WRONG_ADDRESS = "WRONG_ADDRESS";
    uint8 public constant LOAN_PAID_CODE = 0;
    uint8 public constant LOAN_NOT_PAID_CODE = 1;

    struct LoanInfo {
        address scc;
        string idClient;
        string idBusiness;
        uint256 amountCuy;
        uint256 amountFiat;
        uint256 balanceFiat;
        uint256 paidFiat;
        uint256 paidCuy;
        bool open;
    }

    function LoanMessageHandler(uint8 restrictionCode)
        private
        pure
        returns (string memory message)
    {
        if (restrictionCode == LOAN_PAID_CODE) {
            message = LOAN_PAID_ERROR;
        } else if (restrictionCode == LOAN_NOT_PAID_CODE) {
            message = LOAN_NOT_PAID_ERROR;
        }
    }

    modifier loanStatus(
        address account,
        bool status,
        uint8 verificationCode
    ) {
        require(
            debtors[account].open == status,
            LoanMessageHandler(verificationCode)
        );
        _;
    }

    /**
     * This method records the loan details
     * only the crypto credit system (admin) can execute this method
     */
    function loanAdd(
        address account,
        string memory idClient,
        string memory idBusiness,
        uint256 amountCuy,
        uint256 amountFiat,
        uint256 balanceFiat
    ) internal onlyAdmin loanStatus(account, false, LOAN_NOT_PAID_CODE) {
        require(account != address(0), WRONG_ADDRESS);

        debtors[account] = LoanInfo(
            msg.sender,
            idClient,
            idBusiness,
            amountCuy,
            amountFiat,
            balanceFiat,
            0,
            0,
            true
        );
    }

    /**
     * This method obtains the loan data
     */
    function loanBalance(address account)
        public
        view
        returns (LoanInfo memory)
    {
        return debtors[account];
    }

    /**
     * This method records the payment of a loan fee, previously verifying that the loan is still pending payment
     */
    function loanPay(
        address account,
        uint256 paidFiat,
        uint256 paidCuy
    )
        internal
        onlyAdmin
        loanStatus(account, true, LOAN_PAID_CODE)
        returns (bool)
    {
        require(account != address(0), WRONG_ADDRESS);
        debtors[account].paidFiat = debtors[account].paidFiat + paidFiat;
        debtors[account].paidCuy = debtors[account].paidCuy + paidCuy;
        if (debtors[account].paidFiat >= debtors[account].balanceFiat) {
            //the client completed the payment of his credit
            debtors[account].open = false;
        }

        return true;
    }
}

/**
 *Pausable
 *@notice this contract is used to pause cuytoken
 *@author Lenin Tarrillo (lenin.tarrillo.v@gmail.com)
 */
contract Pausable is Owned {
    event PausedEvt(address account);
    event UnpausedEvt(address account);
    string public constant PAUSE_ON_SMJ = "THE_CONTRACT_IS_PAUSE";
    string public constant PAUSE_NO_SMJ = "THE_CONTRACT_NO_PAUSE";
    bool private paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, PAUSE_ON_SMJ);
        _;
    }
    modifier whenPaused() {
        require(paused, PAUSE_NO_SMJ);
        _;
    }

    /**
     * This method is used to pause cuytoken operations
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit PausedEvt(msg.sender);
    }

    /**
     * This method is used to unpause cuytoken operations
     */

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit UnpausedEvt(msg.sender);
    }
}

/**
 *ConditionedSpending
 *@notice The purpose of this contract is to allow people to condition the final spending of the transferred cuytokens.
 *@author Lenin Tarrillo (lenin.tarrillo.v@gmail.com)
 */
contract ConditionedSpending is Owned, Pausable {
    mapping(address => uint256) private conditionedBalances; //conditioned Balances
    mapping(address => mapping(address => uint256)) private wlCBalances; //White list of conditioned Balances

    string public constant CS_FUNDS_ERROR =
        "ILLEGAL_TRANSFER_INSUFFICIENT_FUNDS_TO_PAY";
    string public constant ILLEGAL_PAYMENT =
        "ILLEGAL_PAYMENT_STORE_NOT_ALLOWED";
    string public constant CS_INSUFFICIENT_FUNDS =
        "ILLEGAL_PAYMENT_STORE_NOT_ALLOWED";
    string public constant CS_ERROR_ACCOUNT = "ILLEGAL_ACCOUNT";

    event cPay(address indexed _from, address indexed _to, uint256 _value);

    event BalancesTransform(address sender, address from, uint256 value);

    /**
     * get the conditioned balance of the account
     */
    function balanceConditionedOf(address account)
        public
        view
        returns (uint256)
    {
        return conditionedBalances[account];
    }

    /**
     * this function checks if the account is on the spending whitelist
     */
    function isSpendingWhiteList(address account)
        public
        view
        returns (uint256)
    {
        return wlCBalances[msg.sender][account];
    }

    /**
     * check if the account has permissions to spend in the store
     */
    function checkSpendingWhiteList(address payer, address shop)
        public
        view
        onlyAdmin
        returns (uint256)
    {
        return wlCBalances[payer][shop];
    }

    /**
     * This method makes a transfer in the form of payment to an authorized store,
     * the cuytokens that will be spent will only be those that are marked as conditional balances
     */
    function Pay(address to, uint256 value)
        internal
        whenNotPaused
        returns (bool success)
    {
        require(conditionedBalances[msg.sender] >= value, CS_FUNDS_ERROR);
        require(wlCBalances[msg.sender][to] >= value, ILLEGAL_PAYMENT);
        conditionedBalances[msg.sender] =
            conditionedBalances[msg.sender] -
            value;
        wlCBalances[msg.sender][to] = wlCBalances[msg.sender][to] - value;
        emit cPay(msg.sender, to, value);
        return true;
    }

    /**
     * This method transfers cuytokens and establishes spending restrictions
     * cuytokens with restrictions can only be used to pay in stores
     */
    function transConditioned(
        address to,
        uint256 value,
        address[] memory whitelist
    ) internal whenNotPaused returns (bool success) {
        conditionedBalances[to] = conditionedBalances[to] + value;

        for (uint256 i; i < whitelist.length; i++) {
            wlCBalances[to][whitelist[i]] =
                wlCBalances[to][whitelist[i]] +
                value;
        }

        return true;
    }
}

/**
 *Interface for ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    function increaseAllowance(address _spender, uint256 _addedValue)
        external
        returns (bool success);

    function decreaseAllowance(address _spender, uint256 subtractedValue)
        external
        returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/**
 *CuyToken ERC20
 *@notice The cuytoken implements the ERC20 token
 *@author Lenin Tarrillo (lenin.tarrillo.v@gmail.com)
 */
contract CuyToken is IERC20, Pausable, CriptoCredit, ConditionedSpending {
    TokenSummary public tokenSummary;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public _totalSupply;

    //200 MLL + 18 decimals
    uint256 public constant MAXIMUMSUPPLY = 200000000000000000000000000;

    uint8 public constant SUCCESS_CODE = 0;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    uint8 public constant NON_WHITELIST_CODE = 1;
    string public constant NON_WHITELIST_ERROR =
        "ILLEGAL_TRANSFER_TO_NON_WHITELISTED_ADDRESS";
    string public constant INSUFFICIENT_FUNDS =
        "ILLEGAL_TRANSFER_INSUFFICIENT_FUNDS";

    string public constant ZERO_CUYS_PAY = "ILLEGAL_ATTEMPT_TO_PAY_ZERO_CUYS";
    string public constant ZERO_FIAT_PAY = "ILLEGAL_ATTEMPT_TO_PAY_ZERO_FIAT";
    string public constant MAXIMUMSUPPLY_MSJ = "ILLEGAL_MINING_MAXIMUM_SUPPLY";
    string public constant FUNDS_SUBTRACT_MSJ =
        "INSUFFICIENT_FUNDS_TO_SUBTRACT";
    string public constant ILEGAL_SPENDER_MSJ =
        "ILLEGAL_TRANSFER_UNAUTHORIZED_SPENDER";

    event Burn(address from, uint256 value);
    event Lend(address from, uint256 value);
    event Paid(address from, uint256 value);

    struct TokenSummary {
        address initialAccount;
        string name;
        string symbol;
        uint8 decimals;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialAccount,
        uint256 _initialBalance
    ) {
        balances[_initialAccount] = _initialBalance;
        _totalSupply = _initialBalance;
        tokenSummary = TokenSummary(_initialAccount, _name, _symbol, 18);
    }

    function name() public view override returns (string memory) {
        return tokenSummary.name;
    }

    function symbol() public view override returns (string memory) {
        return tokenSummary.symbol;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view override returns (uint8) {
        return tokenSummary.decimals;
    }

    function messageHandler(uint8 restrictionCode)
        public
        pure
        returns (string memory message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if (restrictionCode == NON_WHITELIST_CODE) {
            message = NON_WHITELIST_ERROR;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(to != address(0), WRONG_ADDRESS);
        require(
            (balances[msg.sender] - balanceConditionedOf(msg.sender)) >= value,
            INSUFFICIENT_FUNDS
        );
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address spender,
        uint256 value
    ) public override whenNotPaused returns (bool) {
        require(spender != address(0), WRONG_ADDRESS);
        require(
            value <= (balances[from] - balanceConditionedOf(from)),
            INSUFFICIENT_FUNDS
        );
        require(value <= allowed[from][msg.sender], ILEGAL_SPENDER_MSJ);

        balances[from] = balances[from] - value;
        balances[spender] = balances[spender] + value;
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        emit Transfer(from, spender, value);
        return true;
    }

    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(spender != address(0), WRONG_ADDRESS);
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(spender != address(0), WRONG_ADDRESS);
        require(
            allowed[msg.sender][spender] >= subtractedValue,
            FUNDS_SUBTRACT_MSJ
        );
        allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(spender != address(0), WRONG_ADDRESS);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 value) public whenNotPaused returns (bool success) {
        require(balances[msg.sender] >= value, INSUFFICIENT_FUNDS);
        balances[msg.sender] -= value;
        _totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }

    /**
     * This method makes a transfer in the form of payment to an authorized store,
     * the cuytokens that will be spent will only be those that are marked as conditional balances
     */
    function payShop(address to, uint256 value)
        public
        whenNotPaused
        returns (bool success)
    {
        require(to != address(0), WRONG_ADDRESS);

        if (Pay(to, value)) {
            balances[to] = balances[to] + value;
            emit Transfer(msg.sender, to, value);
            return true;
        }

        return false;
    }

    /**
     * This method transfers cuytokens and establishes spending restrictions
     * cuytokens with restrictions can only be used to pay in stores previously authorized
     */
    function transferForSpending(
        address to,
        uint256 value,
        address[] memory whitelist
    ) public whenNotPaused returns (bool success) {
        require(to != address(0), WRONG_ADDRESS);
        require(balances[msg.sender] > value, INSUFFICIENT_FUNDS);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        transConditioned(to, value, whitelist);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     *This method mines the cuytokens  and registers the crypto credit
     *This method can only be used by the crypto credit system
     *
     */

    function lend(
        address account,
        string memory idClient,
        string memory idBusiness,
        uint256 amountCuy,
        uint256 amountFiat,
        uint256 balanceFiat
    ) public whenNotPaused onlyAdmin returns (bool) {
        require(account != address(0), WRONG_ADDRESS);

        if (mint(msg.sender, amountCuy)) //mined
        {
            loanAdd(
                account,
                idClient,
                idBusiness,
                amountCuy,
                amountFiat,
                balanceFiat
            ); //Lend
            emit Lend(account, amountCuy);
            return true;
        }

        return false;
    }

    /**
     *This method mines the cuytokens
     *
     */
    function mint(address account, uint256 value)
        internal
        whenNotPaused
        onlyAdmin
        returns (bool)
    {
        require(account != address(0), WRONG_ADDRESS);
        require(_totalSupply + value <= MAXIMUMSUPPLY, MAXIMUMSUPPLY_MSJ);

        _totalSupply += value;
        balances[account] = balances[account] + value;
        emit Transfer(address(0), account, value);
        return true;
    }

    /**
     *This method records the total or partial payment of the crypto credit
     */
    function creditPay(
        address account,
        uint256 amountFiat,
        uint256 amountCuy
    ) public onlyAdmin returns (bool) {
        require(account != address(0), WRONG_ADDRESS);
        require(amountCuy > 0, ZERO_CUYS_PAY);
        require(amountFiat > 0, ZERO_FIAT_PAY);

        if (loanPay(account, amountFiat, amountCuy)) //Record the payment
        {
            burn(amountCuy); //Burn cuytokens
            emit Paid(account, amountCuy);

            return true;
        }
        return false;
    }
}
