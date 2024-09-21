// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController{
    /// @param _minDelay is how long you have to wait before executing
    /// @param proposers is the list of addresses that can propose
    /// @param executors is the list of addresses that can execute
    constructor(uint256 _minDelay, address[] memory proposers, address[] memory executors) TimelockController(_minDelay, proposers, executors, msg.sender){}
}