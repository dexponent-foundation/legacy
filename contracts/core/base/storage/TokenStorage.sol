// SPDX-License-Identifier: MIT 
pragma solidity =0.8.20;
abstract contract TokenStorage {
    event unstakedRequested(address indexed account, uint256 amount, bytes  publicKey);
    uint256[50] private __token_gap;
}