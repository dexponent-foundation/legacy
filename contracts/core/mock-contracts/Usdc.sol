pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    address owner;

    constructor() ERC20("USDC", "USDC") {
        owner = msg.sender;
    }
//  this is only for testing on mainnet we will use the actual USDC address
    function mint(uint256 amount, address account) external {
        _mint(account, amount);
    }
}
