// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

abstract contract TokenStorage {
    uint256 public constant MIN_WITHDRAWAL_AMOUNT = 32 ether;
    event unstakedRequested(
        address indexed account,
        uint256 amount,
        bytes publicKey
    );
    uint256[50] private __token_gap;
}
