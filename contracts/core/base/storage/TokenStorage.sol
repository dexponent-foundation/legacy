// SPDX-License-Identifier: MIT 
pragma solidity =0.8.20;
abstract contract TokenStorage {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => uint256) public rewards;
    event unstakedRequested(address indexed account, uint256 amount, bytes  publicKey);
    uint256[50] private __token_gap;
}