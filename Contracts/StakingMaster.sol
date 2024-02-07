// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./token/Clarb.sol";
import "./StakeHolder.sol";
import "hardhat/console.sol";

// arb token 0x36f9cD0914314BDFF5cCC9604780d0B07E719b5B
contract StakingMaster {
    ClARB private clARB;
    uint256 public totalPool;
    uint256 public lockDuration = 1;
    address public owner;
    mapping(address => StakeHolder) public stakeHolders;
    mapping(address => uint256) public stakedBalance;
    //  change this address when you go for mainnet to mainnet ARB
    IERC20 constant ARB = IERC20(0x36f9cD0914314BDFF5cCC9604780d0B07E719b5B);


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

    constructor(ClARB _clARB) {
        clARB = _clARB;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake(uint256 amount) public {
        StakeHolder stakeHolder = stakeHolders[msg.sender];
        if (address(stakeHolder) == address(0)) {
            stakeHolder = new StakeHolder(msg.sender, address(this),ARB);
            stakeHolders[msg.sender] = stakeHolder;
        }
        IERC20 token = IERC20(ARB);
        require(token.transferFrom(msg.sender, address(stakeHolder), amount));
        stakedBalance[msg.sender] += amount;
        totalPool += amount;
        clARB.mint(msg.sender, amount);
        emit Staked(msg.sender, stakeHolder, amount);
    }



    function unstake(uint256 amount) public  {
        require(amount != 0, "Amount can not be zero");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
        require(clARB.balanceOf(msg.sender) >= amount, "Not enough clARB");
        clARB.burn(msg.sender, amount);
        stakedBalance[msg.sender] -= amount;
        totalPool -= amount;
        StakeHolder user = stakeHolders[msg.sender];
        user.withdrawArb(amount,msg.sender);
        emit Unstaked(msg.sender, amount);
    }



}
