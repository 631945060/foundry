// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";  // 导入 OpenZeppelin 的 Strings 库
// import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
// import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// 自定义错误类型 - 当非合约拥有者执行权限操作时触发
error carbontrader_notowner();
// 自定义错误类型 - 当输入参数不符合要求时触发
error carbontrader_parameter_error();
// 自定义错误类型 - 当转账操作失败时触发
error carbontrader_transferfailed();
// 自定义错误类型 - 当交易状态无效时触发
error carbontrader_invalidtrade();

contract CarbonTrader {
    // 交易结构体定义
    struct trade {
        address seller;
        uint256 sellamount;
        uint256 starttimestamp;
        uint256 endtimestamp;
        uint256 minimumbidamount;
        uint256 initpriceofunit;
    }

    // 状态变量
    mapping (address => uint256) private s_addressToAllowances;
    mapping (address => uint256) private s_addressfreezedamounts;
    mapping (address => uint256) private s_auctionamount;
    mapping (string => trade) private s_trades;
    mapping(string => mapping(address => uint256)) private s_tradeDeposits;

    address private i_owner;
    IERC20 private i_usdtoken;

    // 构造函数
    constructor(address usdtTokenAddress) {
        i_owner = msg.sender;
        i_usdtoken = IERC20(usdtTokenAddress);
    }

    // 权限控制修饰符
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert carbontrader_notowner();
        }
        _;
    }

    // 发放碳配额
    function issueAllowance(address user, uint256 amount) public onlyOwner {
        s_addressToAllowances[user] += amount;
    }

    // 查询用户碳配额
    function getAllowance(address user) public view returns (uint256) {
        return s_addressToAllowances[user];
    }

    // 冻结用户碳配额
    function freezeAllowance(address user, uint256 freezedAmount) public onlyOwner {
        s_addressToAllowances[user] -= freezedAmount;
        s_addressfreezedamounts[user] += freezedAmount;
    }

    // 解冻用户碳配额
    function unfreezeAllowance(address user, uint256 freezeAmount) public onlyOwner {
        s_addressToAllowances[user] += freezeAmount;
        s_addressfreezedamounts[user] -= freezeAmount;
    }

    // 查询用户冻结配额
    function getFreezedAmount(address user) public view returns (uint256) {
        return s_addressfreezedamounts[user];
    }

    // 销毁用户冻结配额
    function destroyAllowance(address user, uint256 destroyAmount) external onlyOwner {
        if (s_addressfreezedamounts[user] < destroyAmount) {
            revert carbontrader_parameter_error();
        }
        s_addressfreezedamounts[user] -= destroyAmount;
    }

    // 开始新的碳配额拍卖
    function starttrade(
        string memory tradeid,
        uint256 amount,
        uint256 starttimestamp,
        uint256 endtimestamp,
        uint256 minimumbidamount,
        uint256 initpriceofunit
    ) public {
        if(amount <= 0 || starttimestamp < block.timestamp || minimumbidamount <= 0 || initpriceofunit <= 0 || minimumbidamount > amount) {
            revert carbontrader_parameter_error();
        }
        trade storage newtrade = s_trades[tradeid];
        newtrade.seller = msg.sender;
        newtrade.sellamount = amount;
        newtrade.starttimestamp = starttimestamp;
        newtrade.endtimestamp = endtimestamp;
        newtrade.minimumbidamount = minimumbidamount;
        newtrade.initpriceofunit = initpriceofunit;

        s_addressToAllowances[msg.sender] -= amount;
        s_addressfreezedamounts[msg.sender] += amount;
    }

    // 获取交易信息
    function gettradeinfo(string memory tradeid) public view returns (
        address, uint256, uint256, uint256, uint256, uint256
    ) {
        trade storage curtrade = s_trades[tradeid];
        return (
            curtrade.seller,
            curtrade.sellamount,
            curtrade.starttimestamp,
            curtrade.endtimestamp,
            curtrade.minimumbidamount,
            curtrade.initpriceofunit
        );
    }

    // 存入保证金
    function deposit(string memory tradeid, uint256 amount) public {
        trade storage curtrade = s_trades[tradeid];
        if (block.timestamp < curtrade.starttimestamp || block.timestamp > curtrade.endtimestamp) {
            revert carbontrader_invalidtrade();
        }
        bool success = i_usdtoken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert carbontrader_transferfailed();

        s_tradeDeposits[tradeid][msg.sender] = amount;
    }

    // 退还保证金
    function refunddeposit(string memory tradeid) public {
        trade storage curtrade = s_trades[tradeid];
        uint256 depositAmount = s_tradeDeposits[tradeid][msg.sender];  // 将 deposit 重命名为 depositAmount
        bool success = i_usdtoken.transfer(msg.sender, depositAmount);
        if (!success) revert carbontrader_transferfailed();
    }

    // 设置竞拍信息
    function setbidinfo(string memory tradeid, string memory info) public {
        trade storage curtrade = s_trades[tradeid];
        curtrade.minimumbidamount = uint256(keccak256(abi.encodePacked(info)));
    }

    // 获取竞拍信息
    function getbidinfo(string memory tradeid) public view returns (uint256) {
        trade storage curtrade = s_trades[tradeid];
        return curtrade.minimumbidamount;
    }

    // 完成交易并转移碳配额
    function finalizeactionandtransfercarbon(string memory tradeid, uint256 allowanceamount, uint256 addtoallowance) public {
        trade storage curtrade = s_trades[tradeid];
        uint256 depositamount = s_tradeDeposits[tradeid][msg.sender];
        uint256 additionalamounttopay = addtoallowance * curtrade.initpriceofunit;

        address seller = curtrade.seller;
        s_auctionamount[seller] += (depositamount + additionalamounttopay);

        s_addressfreezedamounts[seller] = 0;
        s_addressToAllowances[msg.sender] += allowanceamount;
    }

    // 提取拍卖所得
    function withdrawautionamount() public {
        uint256 auctionamount = s_auctionamount[msg.sender];
        bool success = i_usdtoken.transfer(msg.sender, auctionamount);
        if (!success) revert carbontrader_transferfailed();
    }
}