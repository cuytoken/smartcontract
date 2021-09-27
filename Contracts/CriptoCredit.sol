// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./owned.sol";

/**
 * The purpose of Loan contract is manage Lending system
 * add debtors and the information of the loan that is granted to them
 */
contract CriptoCredit is owned {
    mapping(address => LoanInfo) debtors;

    string public constant LOAN_PAID_ERROR = "CLIENTE_HAS_NO_LOAN_TO_PAY";
    string public constant LOAN_NOT_PAID_ERROR = "CLIENT_HAS_AN_UNPAID_LOAN";
    uint8 public constant LOAN_PAID_CODE = 0;
    uint8 public constant LOAN_NOT_PAID_CODE = 1;

    struct LoanInfo {
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
        bool open = debtors[account].open;
        require(open == status, LoanMessageHandler(verificationCode));
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
        uint256 interest
    ) internal onlyAdmin loanStatus(account, false, LOAN_NOT_PAID_CODE) {
        require(account != address(0));
        debtors[account] = LoanInfo(
            msg.sender,
            idClient,
            idBusiness,
            amountCuy,
            amountFiat,
            interest,
            amountFiat * interest,
            amountFiat + (amountFiat * interest),
            amountCuy,
            true
        );
    }

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
        uint256 amountFiat,
        uint256 amountCuy
    )
        internal
        onlyAdmin
        loanStatus(account, true, LOAN_PAID_CODE)
        returns (bool)
    {
        require(account != address(0));
        debtors[account].balanceFiat =
            debtors[account].balanceFiat -
            amountFiat;
        debtors[account].balanceCuy = debtors[account].balanceCuy - amountCuy;
        if (debtors[account].balanceFiat <= 0) {
            //the client completed the payment of his credit
            debtors[account].open = false;
        }

        return true;
    }
}
