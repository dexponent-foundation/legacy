// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./token/CLMatic.sol";
import "./StakeHolder.sol";
import "hardhat/console.sol";

// use deposit to staking master
// call the buyVoucher funcation validator
// deposit 1 Matic as of now
// and mint CLMatic for user
// also withdraw funds call sellVoucher_new on contract

contract StakingMaster {
    CLMatic private clMatic;
    uint256 public totalPool;
    uint256 public lockDuration = 1;
    address public stakeManager = 0x00200eA4Ee292E253E6Ca07dBA5EdC07c8Aa37A3;
    address constant MATIC = 0x499d11E0b6eAC7c0593d8Fb292DCBbF815Fb29Ae;
    address public owner;
    mapping(address => StakeHolder) public stakeHolders;
    mapping(address => uint256) public stakedBalance;



    event Unstaked(address indexed user, uint256 amount);

    event Staked(
        address indexed user,
        StakeHolder stakeHolderContract,
        uint256 amount
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsRestaked(address indexed user, uint256 amount);
    event DepositReceived(address indexed depositor, uint256 amount);
    event WithdrawalMade(address indexed receiver, uint256 amount);

    constructor(CLMatic _clMatic, address _matic) {
        clMatic = _clMatic;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake(uint256 amount,address validator) public {
        require(amount > 1, "Must send ETH to stake");
        StakeHolder stakeHolder = stakeHolders[msg.sender];
        if (address(stakeHolder) == address(0)) {
            stakeHolder = new StakeHolder(msg.sender, address(this), clMatic);
            stakeHolders[msg.sender] = stakeHolder;
        }
        IERC20 token = IERC20(MATIC);
        require(token.transferFrom(msg.sender, address(stakeHolder), amount));
        stakeHolder._buyVoucher(amount, 0, validator, token);
        stakedBalance[msg.sender] += amount;
        totalPool += amount;
        clMatic.mint(msg.sender, amount);
        emit Staked(msg.sender, stakeHolder, amount);
    }



    function unstake(uint256 amount,address validator) public  {
        require(amount != 0, "Amount can not be zero");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
        require(clMatic.balanceOf(msg.sender) >= amount, "Not enough ClMatic");
        clMatic.burn(msg.sender, amount);
        stakedBalance[msg.sender] -= amount;
        totalPool -= amount;
        StakeHolder user = stakeHolders[msg.sender];
        user._sellVoucher(amount, amount, validator);
        emit Unstaked(msg.sender, amount);
    }



}
