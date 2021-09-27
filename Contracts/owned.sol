// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * Define owner, transfer owner and assign admin
 */
contract owned {
    address private _owner;
    mapping(address => bool) admins;

    constructor() {
        _owner = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
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
