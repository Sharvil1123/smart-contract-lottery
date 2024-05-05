//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordindator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
  

    address public PLAYER = makeAddr("player");

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
        entranceFee,
        interval,
        vrfCoordindator,
        gasLane,
        subscriptionId,
        callbackGasLimit
        ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}