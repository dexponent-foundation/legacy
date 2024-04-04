// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../base/modifier/modifier.sol";
/**
 * @title cLETH (clETH)
 * @dev cLETH is an ERC20-compatible token representing clETH (Wrapped ETH) tokens.
 * It provides functionalities such as minting, burning, and pausing of the token.
 * The contract implements ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable,
 * OwnableUpgradeable, and AccessControlUpgradeable from OpenZeppelin.
 */
import "hardhat/console.sol";

contract CLETH is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    Modifiers
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    event clethMinted(address to, uint256 amount);
    event clethBurned(address from, uint256 amount);

    /**
     * @dev Initializes the cLETH contract with the given default admin and staking master addresses.
     * @param defaultAdmin The address to grant default admin role.
     * @param stakingMaster The address to grant burner and minter roles.
     */
    function initialize(
        address defaultAdmin,
        address stakingMaster
    ) public initializer ZeroAddress(defaultAdmin) ZeroAddress(stakingMaster) {
        __ERC20_init("CLETH", "clETH");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(BURNER_ROLE, stakingMaster);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, stakingMaster);
        __Ownable_init(defaultAdmin);
    }

    constructor() {
        _disableInitializers();
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

    /**
     * @dev Mints cLETH tokens to the specified address.
     * Only addresses with the MINTER_ROLE can call this function.
     * @param to The address to mint cLETH tokens to.
     * @param amount The amount of cLETH tokens to mint.
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) ZeroAmount(amount) whenNotPaused {
        _mint(to, amount);
        emit clethMinted(to, amount);
    }

    /**
     * @dev Burns cLETH tokens from the specified account.
     * Only addresses with the BURNER_ROLE can call this function.
     * @param account The address to burn cLETH tokens from.
     * @param amount The amount of cLETH tokens to burn.
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public override ZeroAmount(amount) onlyRole(BURNER_ROLE) whenNotPaused {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _burn(account, amount);
        emit clethBurned(account, amount);
    }

    // The following function is an override required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._update(from, to, value);
    }
}
