// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./owned.sol";

/**
 * the purpose of the Pausable contract is to pause or enable the transfer of cuytokens
 */
/**
 * the purpose of the Pausable contract is to pause or enable the transfer of cuytokens
 */
contract Pausable is owned {
    event PausedEvt(address account);
    event UnpausedEvt(address account);
    bool private paused;

    constructor() {
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
