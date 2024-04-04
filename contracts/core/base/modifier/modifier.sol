// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Modifiers
 * @dev This abstract contract defines two modifiers that are commonly used throughout the system:
 */
abstract contract Modifiers {
    /**
     * @dev Modifier: ZeroAmount
     * @param amount The uint256 amount to check.
     * @notice Ensures that the provided amount is greater than zero.
     */
    modifier ZeroAmount(uint256 amount) {
        require(amount > 0, "Amount cannot be zero");
        _;
    }

    /**
     * @dev Modifier: ZeroAddress
     * @param account The address to check.
     * @notice Ensures that the provided address is not the zero address.
     */
    modifier ZeroAddress(address account) {
        require(account != address(0), "Address cannot be zero");
        _;
    }
}
