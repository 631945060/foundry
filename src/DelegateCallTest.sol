// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract TargetContract{
    uint256 public data;
    constructor(){
        data = 1000;
    }
    function setData(uint256 _data) public {
        data = _data;
    }
}

contract CallLearn{
    uint256 public data;


    function callSetData(address _target,uint256 _data) public{
       (bool success,bytes memory dataByte) =_target.delegatecall(
        abi.encodeWithSignature("setData(uint256)",_data)
        );
        require(success,"call failed");
    }
}
