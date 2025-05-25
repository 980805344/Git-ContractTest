// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// 代理部署
// 实现部署任何合约

contract TestContract1 {
    address public owner = msg.sender;

    modifier OnlyOwner() {
        require (msg.sender == owner, "Not Owner");
        _;
    }

    function setOwner(address _owner) public OnlyOwner {
        require(_owner != address(0), "invalid address");
        owner = _owner;
    }
}

contract TestContract2 {
    address public owner = msg.sender;
    uint256 public value = msg.value;
    uint256 public x;
    uint256 public y;
  
    constructor(uint256 _x, uint256 _y) {
        x = _x;
        y = _y;
    }
}

// 代理合约
contract Proxy {
    event Deploy(address);

    // 部署任何合约
    function deploy(bytes memory _code) external payable returns (address addr) {
        assembly{
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        require(addr != address(0), "deploy failed");
        emit Deploy(addr);
    }

    // 调用其他合约的方法
    function execute(address _target, bytes memory _data) external payable {
    (bool success, ) = _target.call{value: msg.value}(_data);
        require(success, "failed");
    }
}

// 提起合约code，方法code；实际开发中可通过Web3.GS或者ISSGS获取
contract Helper {
    function getBytecode1() external pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract1).creationCode;
        return  bytecode;
    }


    function getBytecode2(uint _x, uint _y) external pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract2).creationCode;
        return  abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

    function getCalldata(address _owner) external pure returns (bytes memory) {
        return abi.encodeWithSignature("function(address)", _owner);
    }
}