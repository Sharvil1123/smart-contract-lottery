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
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

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
        vm.deal(PLAYER, STARTING_USER_BALANCE);  
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // tests to enter raffle

    function testRaffleRevertsWhenYouDontPay() public {
        vm.prank(PLAYER); // ARRANGE - create a mock player with address and eth
        // act / assert
        vm.expectRevert(Raffle.Raffle__notEnoughEthSent.selector);
        raffle.enterRaffle();
    } // testing if sends reverts for not enough eth for participation

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER); // ARRANGE - create a mock player with address and eth
        // act / assert
        raffle.enterRaffle{value : entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER); 
    }       
}