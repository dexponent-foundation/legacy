// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
contract CLETH is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, OwnableUpgradeable ,AccessControlUpgradeable{
    /// @custom:oz-upgrades-unsafe-allow constructor
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


    function initialize(address defaultAdmin)
        initializer public
    {
        __ERC20_init("CLETH", "clETH");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(amount > 0, "CLETH: mint amount must be greater than zero");
        _mint(to, amount);
    }

        function burn(
        address from,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        require(amount > 0, "CLETH: burn amount must be greater than zero");
        _burn(from, amount);
    }
    function grantRoles(
        address stakingMaster
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, stakingMaster);
        grantRole(BURNER_ROLE, stakingMaster);
        grantRole(PAUSER_ROLE, stakingMaster);
    }


    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._update(from, to, value);
    }
}
