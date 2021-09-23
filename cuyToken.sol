// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
/**
 *@notice The cuytoken implements the ERC20 token
 *@author Lenin Tarrillo
 */ 

/**
 * Define owner, transfer owner and assign admin
 */
contract owned {
    address private _owner;
    mapping(address => bool) admins;
    constructor () {
        _owner = msg.sender;
        admins[msg.sender] = true;
    }
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
            _;
    }
    function owner() public view returns(address){
        return _owner;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        _owner = newOwner;
    }
    function isAdmin(address account) onlyOwner public view returns (bool) {   
        return admins[account];
    }
    function addAdmin(address account) onlyOwner public {
        require(account != address(0) && !admins[account]);             
        admins[account] = true;    
    }
    function removeAdmin(address account) onlyOwner public {
        require(account != address(0) && admins[account]);
        admins[account] = false;    
    }
}








/**
 * The purpose of CriptoCredit contract is manage Lending system
 * add debtors and the information of the loan that is granted to them
 */
contract CriptoCredit is owned {
    mapping(address => LoanInfo) debtors;

     string public constant LOAN_PAID_ERROR = "CLIENTE_HAS_NO_LOAN_TO_PAY";
     string public constant LOAN_NOT_PAID_ERROR = "CLIENT_HAS_AN_UNPAID_LOAN";
     uint8 public constant LOAN_PAID_CODE = 0;
     uint8 public constant LOAN_NOT_PAID_CODE = 1;
    
    struct LoanInfo{
        address scc;
        string idClient;
        string idBusiness;
        uint256 amountCuy;
        uint256 amountFiat;
        uint256 interest;
        uint256 interestFiat;
        uint256 balanceFiat;
        uint256 balanceCuy;
        bool open;
        
        
    }
    
   
    

function LoanMessageHandler (uint8 restrictionCode) private pure returns (string memory message) {
        if (restrictionCode == LOAN_PAID_CODE) {
            message = LOAN_PAID_ERROR;
        } else if(restrictionCode == LOAN_NOT_PAID_CODE) {
            message = LOAN_NOT_PAID_ERROR;
        }
    }
    
    
    
modifier loanStatus (address account, bool status, uint8 verificationCode ) {
        bool open = debtors[account].open;
        require(open==status,LoanMessageHandler(verificationCode));
        _;
    }
    
/**
 * This method records the loan details
 * only the crypto credit system (admin) can execute this method
 */
    function loanAdd(address account,string memory idClient,string memory idBusiness, uint256 amountCuy, uint256 amountFiat, uint256 interest ) onlyAdmin loanStatus(account, false,LOAN_NOT_PAID_CODE) internal{
        require(account != address(0));    
        debtors[account] = LoanInfo(msg.sender,idClient,idBusiness,amountCuy,amountFiat,interest,amountFiat*interest,amountFiat + (amountFiat*interest), amountCuy,true );
        
    }
    
   
    
    function loanBalance(address account) public view returns (LoanInfo memory) {   
        return debtors[account];
    }
    
/**
 * This method records the payment of a loan fee, previously verifying that the loan is still pending payment
 */
    function loanPay(address account,uint256 amountFiat,uint256 amountCuy) onlyAdmin  loanStatus(account, true,LOAN_PAID_CODE) internal returns (bool)  {
        require(account != address(0));
        debtors[account].balanceFiat = debtors[account].balanceFiat - amountFiat; 
        debtors[account].balanceCuy = debtors[account].balanceCuy - amountCuy; 
        if(debtors[account].balanceFiat<=0)
        {
            //the client completed the payment of his credit
            debtors[account].open=false;
        }
        
        return true;
        
    }
}




/**
 * the purpose of the Pausable contract is to pause or enable the transfer of cuytokens
 */
contract Pausable is owned {
    event PausedEvt(address account);
    event UnpausedEvt(address account);
    bool private paused;
    constructor (){
        paused = false;
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit PausedEvt(msg.sender);
    }
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit UnpausedEvt(msg.sender);
    }
}

/**
 *Interface for ERC20
 */
interface IERC20 {
    function name() external view returns (string memory );
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 *CuyToken ERC20
 *@notice The cuytoken implements the ERC20 token
 *@author Lenin Tarrillo (lenin.tarrillo.v@gmail.com)
 */
contract CuyToken is IERC20, Pausable, CriptoCredit {
    TokenSummary public tokenSummary;
    mapping(address => uint256) internal balances;
    mapping(address => uint256) internal conditionedBalances; //conditioned Balances
   
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => mapping (address => uint256)) internal wlCBalances; //White list of conditioned Balances
    
    
    
    uint256 public _totalSupply;
    
    
    uint8 public constant SUCCESS_CODE = 0;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    uint8 public constant NON_WHITELIST_CODE = 1;
    string public constant NON_WHITELIST_ERROR = "ILLEGAL_TRANSFER_TO_NON_WHITELISTED_ADDRESS";
    string public constant INSUFFICIENT_FUNDS = "ILLEGAL_TRANSFER_INSUFFICIENT_FUNDS";
    string public constant ILLEGAL_PAYMENT = "ILLEGAL_PAYMENT_STORE_NOT_ALLOWED";
    string public constant ZERO_CUYS_PAY = "ILLEGAL_ATTEMPT_TO_PAY_ZERO_CUYS";
    event Burn(address from, uint256 value);
    event Lend(address from, uint256 value);
    event Paid(address from, uint256 value);
    
     event BalancesTransform(address sender,address from, uint256 value);
    
    
    
    struct TokenSummary {
        address initialAccount;
        string name;
        string symbol;
        uint8 decimals;
        
    }
    constructor(string memory _name, string memory  _symbol, address _initialAccount, uint _initialBalance)  {
        balances[_initialAccount] = _initialBalance;
        _totalSupply = _initialBalance;
        tokenSummary = TokenSummary(_initialAccount, _name, _symbol,18);
    }

    function name() public view override   returns (string memory) {
        return tokenSummary.name;
    }

     function symbol() public view override  returns (string memory) {
        return tokenSummary.symbol;
    }
    function totalSupply() external view override returns (uint256){
        return _totalSupply;
    }
    
     function decimals() public view override  returns (uint8) {
        return  tokenSummary.decimals;
    }

   
   
    function messageHandler (uint8 restrictionCode) public pure returns (string memory message) {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if(restrictionCode == NON_WHITELIST_CODE) {
            message = NON_WHITELIST_ERROR;
        }
    }
    
    function balanceOf(address account) public  view override returns (uint256) {
      return balances[account];
    }
    
    
    function balanceConditionedOf(address account) public  view  returns (uint256) {
      return conditionedBalances[account];
    }
    
    
    function isWhiteList(address account) public  view  returns (uint256) {
      return wlCBalances[msg.sender][account];
    }
   
   
   
    function transfer (address to, uint256 value) public override 
    whenNotPaused  returns (bool success) {
        require(to != address(0) && (balances[msg.sender] - conditionedBalances[msg.sender])>= value, INSUFFICIENT_FUNDS);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
/**
  * This method makes a transfer in the form of payment to an authorized store, 
  * the cuytokens that will be spent will only be those that are marked as conditional balances
 */
     function shopPay(address to, uint256 value) public 
    whenNotPaused  returns (bool success) {
        require(to != address(0) && conditionedBalances[msg.sender]>= value, INSUFFICIENT_FUNDS);
        require(wlCBalances[msg.sender][to]>= value, ILLEGAL_PAYMENT);
        conditionedBalances[msg.sender] = conditionedBalances[msg.sender] - value;
        wlCBalances[msg.sender][to]=wlCBalances[msg.sender][to] - value;
         balances[to] = balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    function transferFrom(address from, address spender,uint256 value) public override   whenNotPaused returns (bool) {
        require(spender != address(0) && value <= (balances[from] - conditionedBalances[from] ) && value <= allowed[from][msg.sender], INSUFFICIENT_FUNDS );
        balances[from] = balances[from] - value;
        balances[spender] = balances[spender] + value;
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        emit Transfer(from, spender, value);
        return true;
  }
  function allowance(address _owner,address spender) public  view override returns (uint256) {
    return allowed[_owner][spender];
  }
  
  
  
  function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
   }
   
  function burn(uint256 value) public whenNotPaused  returns (bool success) {
    require(balances[msg.sender] >= value); 
    balances[msg.sender] -= value; 
    _totalSupply -= value;
    emit Burn(msg.sender, value);
    return true;
 }
 
 
 
 /**
  * This method transfers cuytokens and establishes spending restrictions
  * cuytokens with restrictions can only be used to pay in stores
 */
  function transferConditioned (address to, uint256 value, address[] memory whitelist) public 
    whenNotPaused  returns (bool success) {
        require(to != address(0) && balances[msg.sender]> value);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        conditionedBalances[to] = conditionedBalances[to] + value;
        
        for(uint i; i<whitelist.length; i++)
        {
            wlCBalances[to][whitelist[i]] =  wlCBalances[to][whitelist[i]] + value;
        }
            
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    
 /**
  * This method free from restrictions the conditioned balance of an account
  * they can only be called by administrators. off chain should have sustained the change
 */
  function balancesTransform(address from, uint256 value) onlyAdmin public 
    whenNotPaused  returns (bool success) {
        require(from != address(0) && balances[from]> value);
        
        conditionedBalances[from] = conditionedBalances[from] - value;
        
        emit BalancesTransform(msg.sender, from, value);
        return true;
    }
    
 
 
 
 /**
 *This method mines the cuytokens  and registers the crypto credit
 *This method can only be used by the crypto credit system
 *
 */
 
 function lend(address account,string memory idClient,string memory idBusiness, uint256 amountCuy, uint256 amountFiat, uint256 interest )  public whenNotPaused onlyAdmin returns (bool){
        require(account != address(0)); 
        
        if(mint(msg.sender,  amountCuy))//mined
        {
            
        loanAdd(account,  idClient,  idBusiness,  amountCuy,  amountFiat,  interest ); //Lend
        emit Lend(account,amountCuy);
        return true;
            
        }
        
        return false;
        
       
        
    }
    
/**
 *This method mines the cuytokens  
 *
 */    
  function mint(address account, uint256 value) internal whenNotPaused onlyAdmin returns (bool) {
    require(account != address(0));
    _totalSupply += value;
    balances[account] = balances[account] + value;
    emit Transfer(address(0), account, value);
    return true;
      
  }
  
  
  
  /**
 *This method records the total or partial payment of the crypto credit
 */
  function creditPay(address account,uint256 amountFiat,uint256 amountCuy) onlyAdmin internal returns (bool) {
        require(account != address(0) && amountCuy>0, ZERO_CUYS_PAY );
        
        if(loanPay(account, amountFiat, amountCuy))//Record the payment
        {
            burn(amountCuy); //Burn cuytokens
            emit Paid(account,amountCuy);
            
            return true;
        }
        return false;
    }

   
  
}
