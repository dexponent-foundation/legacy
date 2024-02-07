// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARB is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => uint256) public rewards;
    event unstakedRequested(address indexed account, uint256 amount, bytes  publicKey);

    constructor() ERC20("ARB Token", "ARB") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _mint(msg.sender, 1000*1e18);
    }

    function mint(
        address to,
        uint256 amount
    ) external  {
        _mint(to, amount);
    }
}
