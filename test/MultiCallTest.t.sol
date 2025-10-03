// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/MultiCallTest.sol";

contract MultiCallTestTest is Test {
    MultiCall multiCall;
    MultiCallTest multiCallTest;
    ContractA contractA;
    ContractB contractB;

    function setUp() public {
        // 部署合约
        multiCall = new MultiCall();
        multiCallTest = new MultiCallTest(address(multiCall));
        contractA = new ContractA();
        contractB = new ContractB();
    }

    function testMultiCall() public {
        // 测试直接使用 MultiCall 合约
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        calls[0] = MultiCall.Call(address(contractA), abi.encodeWithSignature("setData(uint256)", 2000));
        calls[1] = MultiCall.Call(address(contractB), abi.encodeWithSignature("setData(uint256)", 3000));
        
        multiCall.multicall(calls);
        
        // 验证数据是否正确更新
        assertEq(contractA.dataA(), 2000, "ContractA data not updated correctly");
        assertEq(contractB.dataB(), 3000, "ContractB data not updated correctly");
    }

    function testMultiCallTest() public {
        // 测试使用 MultiCallTest 合约
        multiCallTest.setValues(address(contractA), 5000, address(contractB), 6000);
        
        // 验证数据是否正确更新
        assertEq(contractA.dataA(), 5000, "ContractA data not updated correctly through MultiCallTest");
        assertEq(contractB.dataB(), 6000, "ContractB data not updated correctly through MultiCallTest");
    }

    function testMultiCallFailure() public {
        // 创建一个无效的调用（指向不存在的函数）
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        calls[0] = MultiCall.Call(address(contractA), abi.encodeWithSignature("setData(uint256)", 2000));
        calls[1] = MultiCall.Call(address(contractB), abi.encodeWithSignature("nonExistentFunction(uint256)", 3000));
        
        // 预期调用会失败
        vm.expectRevert("call item failed");
        multiCall.multicall(calls);
    }

    function testContractADirectCall() public {
        // 测试直接调用 ContractA
        contractA.setData(7000);
        assertEq(contractA.dataA(), 7000, "ContractA direct call failed");
    }

    function testContractBDirectCall() public {
        // 测试直接调用 ContractB
        contractB.setData(8000);
        assertEq(contractB.dataB(), 8000, "ContractB direct call failed");
    }

    function testCallLearn() public {
        // 测试 CallLearn 合约
        CallLearn callLearn = new CallLearn();
        
        // 使用 CallLearn 调用 ContractA
        callLearn.callSetData(address(contractA), 9000);
        assertEq(contractA.dataA(), 9000, "CallLearn failed to update ContractA");
        
        // 使用 CallLearn 调用 ContractB
        callLearn.callSetData(address(contractB), 10000);
        assertEq(contractB.dataB(), 10000, "CallLearn failed to update ContractB");
    }
}