// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract MultiCall{
   struct Call{
    address targetAddress;
    bytes callData;
   }
   constructor(){

   }
   function multicall(Call[] memory calls) public{
    for(uint256  i=0  ;i < calls.length;i++){
        (bool success,) =calls[i].targetAddress.call(calls[i].callData);
        require(success,"call item failed");
    }
   }
}


contract ContractA{
    uint256 public dataA;
    constructor(){
        dataA = 1000;
    }
    function setData(uint256 _data) public {
        dataA = _data;
    }
}
contract ContractB{
    uint256 public dataB;
    constructor(){
        dataB = 1000;
    }
    function setData(uint256 _data) public {
        dataB = _data;
    }
}
contract CallLearn{
    function callSetData(address _target,uint256 _data) public{
       (bool success, ) =_target.call(
        abi.encodeWithSignature("setData(uint256)",_data)
        );
        require(success,"call failed");
    }
}


contract MultiCallTest{
    MultiCall public immutable multiCall;
    constructor(address _multicall){
        multiCall = MultiCall(_multicall);    
    }
    
    function setValues(address _contractA,uint256 _dataA,address _contractB,uint256 _dataB) public{
        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        calls[0] = MultiCall.Call(_contractA,abi.encodeWithSignature("setData(uint256)",_dataA));
        calls[1] = MultiCall.Call(_contractB,abi.encodeWithSignature("setData(uint256)",_dataB));
        multiCall.multicall(calls);
    }
}