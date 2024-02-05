// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WCLETH is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => uint256) public rewards;
    event unstakedRequested(address indexed account, uint256 amount, bytes32 publicKey);

    constructor() ERC20("WCLETH Token", "WCLETH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(amount > 0, "CLETH: mint amount must be greater than zero");
        _mint(to, amount);
    }

    function unstake(uint256 amount,bytes32  publicKey) public whenNotPaused {
        require(amount > 0, "CLETH: burned amount must be greater than zero");
        _burn(msg.sender, amount);
        emit unstakedRequested(msg.sender, amount,publicKey);
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
