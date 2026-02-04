// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from  "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        return deployRaffle();
    } 

    function deployRaffle() external returns (Raffle, HelperConfig) {
        HelperConfig config = new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit,
            config.subscriptionId,
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}