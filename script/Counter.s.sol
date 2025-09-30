// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {
        
    }

    function run() public {
       // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署合约
        Counter counter = new Counter();
        
        // 停止广播
        vm.stopBroadcast();
        
        // 输出部署地址
        console.log("Counter deployed at:", address(counter));
    }
}
