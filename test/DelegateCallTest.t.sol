// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/DelegateCallTest.sol";
    // Adjust the path to your MyNFT contract

contract CallLearnTest is Test {
    CallLearn public callLearn;
    TargetContract public targetContract;
    function setUp() public {
        callLearn = new CallLearn();
        targetContract = new TargetContract();
    }
    function testCallSetData() public {
        callLearn.callSetData(address(targetContract), 2000);
        assertEq(callLearn.data(), 2000);
    }
   
}