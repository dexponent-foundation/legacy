// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../base/storage/TokenStorage.sol";
contract WCLETH is ERC20, AccessControl, Pausable ,TokenStorage {
    constructor() ERC20("wclETH Token", "wclETH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(amount > 0, "WCLETH: mint amount must be greater than zero");
        _mint(to, amount);
    }

    function unstake(uint256 amount,bytes calldata pubkeys) public whenNotPaused {
        //TODO make    require(amount >= 32, "CLETH: burned amount must be greater than zero");
        require(amount > 0, "WCLETH: burned amount must be greater than zero");
        _burn(msg.sender, amount);
        emit unstakedRequested(msg.sender, amount,pubkeys);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function grantRoles(address owner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, owner);
        grantRole(PAUSER_ROLE, owner);
    }
}
