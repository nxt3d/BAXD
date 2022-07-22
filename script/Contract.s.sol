// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { BAXD20 } from "src/BAXD20.sol";
import "src/IMetadataService.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ContractScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new BAXD20(IERC20(address(0)),IMetadataService(address(0)));
        vm.stopBroadcast();
    }
}
