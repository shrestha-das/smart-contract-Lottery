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



// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


    /** 
     *@title A sample Raffle contract
     *@author Shrestha Das
     *@notice This contract is for creating a sample raffle contract
     *@dev Implements Chainlink VRFv2.5 
     */

contract Raffle is VRFConsumerBaseV2Plus {

    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed(); 
    error Raffle__RaffleNotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN, 
        CALCULATING
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS =1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players; // address payable[] to store list of players, who can receive ETH that's why payable
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor ( uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 
    gasLane, uint256 subscriptionId, uint32 callbackGasLimit ) 
    VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        // s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable{
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter raffle");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()");;
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }  

        s_players.push(payable(msg.sender));

        // 1. Events makes migration easier 
        // 2. makes frontend "indexing" events, easier to search
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(bytes calldata /* checkData */) 
    public 
    view 
    returns (bool upkeepNeeded, bytes memory /* performData */) {
        
    }

    // 1. Get a random winner (verifiably random)
    // 2. Use that ranfom number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enough time is passed
        if((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        // Get our random number from chainlink VRF2.5
        // (two-transaction process)
        // 1. Request Random Number Generator(RNG)
        // 2. Get RNG
        
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set native payment to true to pay fo VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestID = s_vrfCoordinator.requestRandomWords(request);

    }

    // CEI : Checks, Effects, Interactions pattern
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Checks
        // conditionals

        // s_player = 10
        // rng = 12
        // 12 % 10 = 2 
        // 68709776564456987657865456787654e5 % 10 = 9


        // Effects (Internal Contract State)
        uint indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        
        emit WinnerPicked(s_recentWinner);


        // Interactions
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

    }

    /*
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}