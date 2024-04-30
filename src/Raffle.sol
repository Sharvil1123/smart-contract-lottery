// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title A sample Raffle Contract
 * @author Sharvil Bhalke
 * @notice This contract is for creating a sample raffle
 * @dev Implements a ChainLink VRFv2
 */

contract Raffle{
    uint256 private immutable i_entranceFee; // immutable so that we can save gas.

    constructor(uint256 entranceFee){
        i_entranceFee = entranceFee;
    }
    function enterRaffle() public payable{
        //the function is payable cause we want collect some eth in terms of fees.
    }

    function pickWinner() public {}

    /** Getter function */

   function getEntranceFee() external view returns(uint256){
    return i_entranceFee;
   }
}