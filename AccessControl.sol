// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract AccessControl {
    // 授予角色
    event GrantRole(bytes32 indexed role, address indexed account);
    // 撤销角色
    event RevokeRole(bytes32 indexed role, address indexed account);

    // 角色
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));
    // 账户是否拥有这个角色
    mapping (bytes32=>mapping(address=>bool)) public roles;

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authrized");
        _;
    }

    constructor() {
        // 初始化部署者为ADMIN
        _grantRole(ADMIN, msg.sender);
    }
    // 赋予角色
    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }
    // 赋予角色外部调用
    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

}