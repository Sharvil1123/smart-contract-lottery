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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
 * @title A sample Raffle Contract
 * @author Sharvil Bhalke
 * @notice This contract is for creating a sample raffle
 * @dev Implements a ChainLink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__notEnoughEthSent();
    error Raffle__transferFailed();
    error Raffle__raffleNotOpen();
    error Raffle__upKeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /* Type declarations */
    enum RaffleState{
        OPEN,       // 0
        CALCULATING // 1
    }

    // Checks (requires and reverts)
    // Effects (in our own contract)
    // Interactions (external contracts)

    // done with the wsl

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee; // immutable so that we can save gas.
    uint256 private immutable i_interval; // immutable, and set duration of lottery in seconds
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players; // a array that stores addresses of players. stored in storage.
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordindator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordindator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordindator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        //the function is payable cause we want collect some eth in terms of fees.
        // use custom errors as they are more gas efficient than require statements.
        // require(msg.value >= i_entranceFee, "Not enough eth");
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEthSent();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__raffleNotOpen(); 
        }
        s_players.push(payable(msg.sender)); // when ebntered the lottery, the players(payable) add will be pushed to array
        // events --> 1. makes migration easier        2. makes front end indexing easier
        emit EnteredRaffle(msg.sender);
    }

    // When the wineers are supposed to be picked?
    /**
     * @dev This is the function that chainlink automation nodes call to see if its time to perform the upkeep.
     * The following should be true for this to return true
     * 1. The time interval has passed between raffle runs.
     * 2. The raffle is in open state
     * 3. The contract has ETH(players)
     * 4. (Implicit) The subscription is funded with link
    */
   function checkUpKeep(
    bytes memory /*checkData */
   ) public view returns(
    bool upKeepNeeded,
    bytes memory /*performData*/
   ){
    bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
    bool isOpen = RaffleState.OPEN == s_raffleState;
    bool hasBalance = address(this).balance > 0;
    bool hasPlayers = s_players.length > 0;
    upKeepNeeded = (timeHasPassed && hasBalance && hasPlayers && isOpen);
    return (upKeepNeeded, "0x0");
   }


    function performUpKeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, )  = checkUpKeep("");
        if(!upKeepNeeded){
            revert Raffle__upKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // 1. Get a random number
        // 2. use the random number to pick a player
        // 2. be automatically called.

        // check enough time is passed

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
        // request the rng
        // get the random number.
    }


    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable [](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value : address(this).balance}("");
        if(!success){
            revert Raffle__transferFailed();
        }
        emit PickedWinner(winner);
    }
    /**Getter functions */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
     // we will refactor the code.

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256){
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
}
