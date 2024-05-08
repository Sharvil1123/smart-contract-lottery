//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordindator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

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
            callbackGasLimit,
            link
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
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitEventsOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");

        vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }


    function testCheckUpkeepReturnsFalseForNoValue() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act 
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        
        // Assert 
        assert(!upKeepNeeded);
    }

    
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        // act 
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        
        // Assert 
        assert(upKeepNeeded == false);
    }

    //testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        assert(upKeepNeeded == false);

    }
    //testCheckUpkeepReturnsTrueWhenParametersAreGood.

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");

        assert(upKeepNeeded);
    }

    // perform upkeep tests

    function testPerformUpkeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpKeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpKeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__upKeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );

        raffle.performUpKeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }   

    // What if I need to test using the output of an event? 

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed{
        vm.recordLogs(); // record the emitted logs of the events
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // all logs are recorded in bytes32 in foundry
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();


        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordindator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

}