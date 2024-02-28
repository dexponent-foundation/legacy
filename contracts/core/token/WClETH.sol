// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../base/storage/TokenStorage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract wclETH is
    ERC20Upgradeable,
    TokenStorage,
    OwnableUpgradeable,
    PausableUpgradeable
{
    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init(msg.sender);
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "WCLETH: mint amount must be greater than zero");
        _mint(to, amount);
    }

    function unstake(
        uint256 amount,
        bytes calldata pubkeys
    ) public whenNotPaused {
        require(amount > 0, "WCLETH: burned amount must be greater than zero");
        _burn(msg.sender, amount);
        emit unstakedRequested(msg.sender, amount, pubkeys);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function unpaus1e() public pure returns (string memory) {
        return "HELLo";
    }
}
