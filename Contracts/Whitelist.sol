// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./owned.sol";

/**
 * The purpose of Whitelist contract is manage whitelist
 * Only accounts that are whitelisted will be able to hold cuytokens
 */
contract Whitelist is owned {
    mapping(address => bool) whitelist;

    function addWhitelist(address account) public onlyAdmin {
        require(account != address(0) && !whitelist[account]);
        whitelist[account] = true;
    }

    function isWhitelist(address account) public view returns (bool) {
        return whitelist[account];
    }

    function removeWhitelisted(address account) public onlyAdmin {
        require(account != address(0) && whitelist[account]);
        whitelist[account] = false;
    }
}
