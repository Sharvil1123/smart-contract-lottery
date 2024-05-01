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
    error Raffle__notEnoughEthSent() ;
    uint256 private immutable i_entranceFee; // immutable so that we can save gas.
    uint256 private immutable i_interval; // immutable, and set duration of lottery in seconds
    address payable[] private s_players; // a array that stores addresses of players. stored in storage.
    uint256 private s_lastTimeStamp;
    
    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable{
        //the function is payable cause we want collect some eth in terms of fees.
        // use custom errors as they are more gas efficient than require statements.
        // require(msg.value >= i_entranceFee, "Not enough eth");
        if(msg.value < i_entranceFee){
            revert Raffle__notEnoughEthSent();
        }
        s_players.push(payable(msg.sender)); // when ebntered the lottery, the players(payable) add will be pushed to array
        // events --> 1. makes migration easier        2. makes front end indexing easier
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() external{
        // 1. Get a random number
        // 2. use the random number to pick a player    
        // 2. be automatically called.

        // check enough time is passed
        if((block.timestamp - s_lastTimeStamp) < i_interval){
            revert();
        }
    }

    /** Getter function */

   function getEntranceFee() external view returns(uint256){
    return i_entranceFee;
   }
}