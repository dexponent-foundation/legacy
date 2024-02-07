// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CLETH is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => uint256) public rewards;

    constructor() ERC20("clETH Token", "clETH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(amount > 0, "CLETH: mint amount must be greater than zero");
        _mint(to, amount);
    }
// 0xFd7012D3beCCc0836070F43ae15663717B57Ac2d cleth 
// 0x4eF4E73186B6DC5f89c3342f1CC10949c4cfe02B staking master 
    function burn(
        address from,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        require(amount > 0, "CLETH: burn amount must be greater than zero");
        _burn(from, amount);
    }

    function addReward(
        address account,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        rewards[account] += amount;
    }

    function setReward(
        address account,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        rewards[account] = amount;
    }

    function claimReward(address account) public {
        uint256 reward = rewards[account];
        require(reward > 0, "No rewards to claim");
        rewards[account] = 0;
        _mint(account, reward);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function grantRoles(
        address stakingMaster
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, stakingMaster);
        grantRole(BURNER_ROLE, stakingMaster);
        grantRole(PAUSER_ROLE, stakingMaster);
    }
}
