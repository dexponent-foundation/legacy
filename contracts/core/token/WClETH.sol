// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../base/storage/TokenStorage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title Wrapped clETH (wclETH)
 * @dev wclETH is an ERC20-compatible token representing wrapped clETH tokens.
 * Users can mint wclETH tokens by depositing clETH tokens and unstake clETH tokens by burning wclETH tokens.
 * The contract implements ERC20Upgradeable, TokenStorage, OwnableUpgradeable, and PausableUpgradeable from OpenZeppelin.
 */
import "hardhat/console.sol";

contract wclETH is
    ERC20Upgradeable,
    TokenStorage,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /**
     * @dev Initializes the wclETH contract with the given name and symbol.
     * @param name_ The name of the wclETH token.
     * @param symbol_ The symbol of the wclETH token.
     */
    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        console.log("hello",msg.sender);
        __ERC20_init(name_, symbol_);
        __Ownable_init(msg.sender);
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Mints wclETH tokens to the specified address.
     * Only the owner can call this function.
     * @param to The address to mint wclETH tokens to.
     * @param amount The amount of wclETH tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "WCLETH: mint amount must be greater than zero");
        require(to != address(0), "Zero address");
        _mint(to, amount);
    }

    /**
     * @dev Burns wclETH tokens and requests the unstaking of clETH tokens.
     * @param amount The amount of wclETH tokens to burn.
     * @param pubkeys The public keys associated with the unstaking request.
     */
    function unstake(
        uint256 amount,
        bytes calldata pubkeys
    ) public whenNotPaused {
        require(amount > 0, "WCLETH: burned amount must be greater than zero");
        require(pubkeys.length == 48, "Length of pubkeys must be 48 bytes");
        require(amount == MIN_WITHDRAWAL_AMOUNT, "Must sent 32 wclETH");
        _burn(msg.sender, amount);
        emit unstakedRequested(msg.sender, amount, pubkeys);
    }

    /**
     * @dev Pauses the contract. Only the owner can call this function.
     */

    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only the owner can call this function.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
