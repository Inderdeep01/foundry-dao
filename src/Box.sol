// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable{
    constructor() Ownable(msg.sender){}

    uint256 private s_number;
    
    event NumberChanged(uint256 number);

    function store(uint256 newValue) public onlyOwner {
        s_number = newValue;
        emit NumberChanged(newValue);
    } 

    function getNumber() external view returns(uint256){
        return s_number;
    }
}