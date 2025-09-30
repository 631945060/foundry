// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {CarbonTrader} from "../src/CarbonTrader.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract CarbonTraderTest is Test {
    ERC20Mock public usdtToken;
    CarbonTrader public carbonTrader;

    address public owner = address(this);
    address public user1 = address(0xA11CE);
    address public user2 = address(0xB0B);

    function setUp() public {
        usdtToken = new ERC20Mock(
            "USDT",
            "USDT",
            address(this),
            1000000000000000000000000
        );

        carbonTrader = new CarbonTrader(address(usdtToken));
    }
    function test_issueAllowance() public {
        carbonTrader.issueAllowance(address(this), 1000);
        assertEq(carbonTrader.getAllowance(address(this)), 1000);
    }
    function test_FreezeAllowance() public {
        carbonTrader.issueAllowance(user1, 1000);
        carbonTrader.freezeAllowance(user1, 500);
        assertEq(carbonTrader.getAllowance(user1), 500);
        assertEq(carbonTrader.getFreezedAmount(user1), 500);
    }
    function test_UnfreezeAllowance() public {
        carbonTrader.issueAllowance(user1, 1000);
        carbonTrader.freezeAllowance(user1, 500);
        assertEq(carbonTrader.getAllowance(user1), 500);
        assertEq(carbonTrader.getFreezedAmount(user1), 500);
        carbonTrader.unfreezeAllowance(user1, 500);
        assertEq(carbonTrader.getAllowance(user1), 1000);
        assertEq(carbonTrader.getFreezedAmount(user1), 0);
    }
    function test_DestroyAllowance() public {
        //给owner发放1000碳配额，冻结500碳配额
        carbonTrader.issueAllowance(owner, 1000);
         assertEq(carbonTrader.getAllowance(owner), 1000);
        //冻结500碳配额
        carbonTrader.freezeAllowance(owner, 500);
        assertEq(carbonTrader.getAllowance(owner), 500);
        //验证user1不能销毁owner的碳配额
        vm.prank(user1);
        //验证销毁失败
        vm.expectRevert();
        //销毁500碳配额
        carbonTrader.destroyAllowance(owner, 500);
        //验证owner的碳配额为0
        // assertEq(carbonTrader.getAllowance(owner), 500);
        carbonTrader.freezeAllowance(owner, 500);
        carbonTrader.destroyAllowance(owner, 500);
        assertEq(carbonTrader.getAllowance(owner), 0);
    }
}
