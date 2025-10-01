
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BaseERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    // 记录授权关系
    // allowances[owner][spender] => owner 允许 spender 转账的最大代币数量
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // write your code here
        require(
            balances[msg.sender] >= _value,
            "ERC20: transfer amount exceeds balance"
        );
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // write your code here
        require(
            allowances[_from][msg.sender] >= _value,
            "ERC20: transfer amount exceeds allowance"
        );
        // ✅ 2. 检查 _from 地址是否有足够余额
        require(
            balances[_from] >= _value,
            "ERC20: transfer amount exceeds balance"
        );
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        // write your code here
        return allowances[_owner][_spender];
    }
}

// 引入你的 BaseERC20 合约接口（或直接部署后传地址）
interface IBaseERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenBank {
    // 存储你的 BaseERC20 代币合约实例
    IBaseERC20 public token;

    // 记录每个用户存了多少代币
    mapping(address => uint256) public deposits;

    // 事件：记录存款和取款行为
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // 构造函数：传入你部署好的 BaseERC20 合约地址
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "TokenBank: invalid token address");
        token = IBaseERC20(_tokenAddress);
    }

    /**
     * @notice 存入代币
     * @param amount 要存入的数量（必须先调用 approve）
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "TokenBank: amount must be greater than 0");

        // 更新该用户的存款记录
        deposits[msg.sender] += amount;

        // 从用户账户中把代币转移到 TokenBank 合约
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "TokenBank: transferFrom failed");

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice 提取代币
     * @param amount 要提取的数量
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "TokenBank: amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "TokenBank: insufficient balance");

        // 减少用户存款记录
        deposits[msg.sender] -= amount;

        // 把代币从银行合约转回用户钱包
        bool success = token.transfer(msg.sender, amount);
        require(success, "TokenBank: transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice 查询某用户的存款余额
     * @param user 用户地址
     * @return 该用户在银行的存款数量
     */
    function getDepositBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    /**
     * @notice 查询银行合约当前持有的总代币量
     * @return 银行中总共存了多少代币
     */
    function getTotalBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}