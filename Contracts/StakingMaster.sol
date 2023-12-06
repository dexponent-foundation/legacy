// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CLETH.sol";

contract StakingMaster {
    CLETH private clethToken;
    mapping(address => uint256) private stakedBalance;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => UserAction[]) public userHistory;
    uint256 public totalPool;
    uint256 public lockDuration = 1 days;
    address public Owner;

    enum ActionType { Staked, Restaked, Withdrawn, Unstaked }
    struct UserAction {
        ActionType actionType;
        uint256 amount;
        uint256 timestamp;
    }

    event Withdrawn(address indexed user, uint256 amount);
    event RewardsRestaked(address indexed user, uint256 amount);
    modifier onlyOwner() {
    require(msg.sender == Owner, "Only the contract deployer can execute this");
    _;
}

   constructor(CLETH _clethToken) {
    clethToken = _clethToken;
   // Owner = msg.sender;
}


    function stake() public payable {
        stakedBalance[msg.sender] += msg.value;
        clethToken.mint(msg.sender, msg.value);
        lastStakeTime[msg.sender] = block.timestamp;
        totalPool += msg.value;
        userHistory[msg.sender].push(UserAction(ActionType.Staked, msg.value, block.timestamp));
    }


    function restakeRewards() public {
        uint256 reward = clethToken.rewards(msg.sender);
        require(reward > 0, "No rewards to re-stake");
        require(block.timestamp >= lastStakeTime[msg.sender] + lockDuration, "Tokens are still locked");
        
        clethToken.setReward(msg.sender, 0); 
        
        
        stakedBalance[msg.sender] += reward;
        lastStakeTime[msg.sender] = block.timestamp;
        totalPool += reward;
        userHistory[msg.sender].push(UserAction(ActionType.Restaked, reward, block.timestamp));
        emit RewardsRestaked(msg.sender, reward);
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= lastStakeTime[msg.sender] + lockDuration, "Tokens are still locked");
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
        stakedBalance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        totalPool -= amount;
        userHistory[msg.sender].push(UserAction(ActionType.Withdrawn, amount, block.timestamp));
        emit Withdrawn(msg.sender, amount);
    }

    function unstake(uint256 amount) public onlyWhitelisted notBlacklisted{
        require(block.timestamp >= lastStakeTime[msg.sender] + lockDuration, "Tokens are still locked");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
        require(clethToken.balanceOf(msg.sender) >= amount, "Not enough CLETH tokens");
        stakedBalance[msg.sender] -= amount;
        clethToken.burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        totalPool -= amount;
        userHistory[msg.sender].push(UserAction(ActionType.Unstaked, amount, block.timestamp));
    }

    function distributeRewards(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            clethToken.addReward(recipients[i], amounts[i]);
        }
    }

    function claimRewards() public {
        clethToken.claimReward(msg.sender);
    }

    // function slashAccount(address account, uint256 amount) public {
    //     clethToken.burn(account, amount);
    // }

    function pauseCLETH() public {
        clethToken.pause();
    }

    function unpauseCLETH() public {
        clethToken.unpause();
    }

    function getStakedBalance(address account) public view returns (uint256) {
        return stakedBalance[account];
    }

    function getUserHistory(address user) public view returns (UserAction[] memory) {
        return userHistory[user];
    }

    function updateLockDuration(uint256 newDuration) public {
        require(newDuration > 0, "Lock duration must be positive");
        lockDuration = newDuration;
    }
    

enum UserStatus { Unknown, Whitelisted, Blacklisted }
mapping(address => UserStatus) public userStatus;

modifier onlyWhitelisted() {
    require(userStatus[msg.sender] == UserStatus.Whitelisted, "User is not whitelisted");
    _;
}

modifier notBlacklisted() {
    require(userStatus[msg.sender] != UserStatus.Blacklisted, "User is blacklisted");
    _;
}

function addToWhitelist(address user) public onlyOwner {
    
    userStatus[user] = UserStatus.Whitelisted;
}

function addToBlacklist(address user) public onlyOwner{
   
    userStatus[user] = UserStatus.Blacklisted;
}

function removeFromWhitelist(address user) public onlyOwner{
    
    userStatus[user] = UserStatus.Unknown;
}

function removeFromBlacklist(address user) public  onlyOwner{
    
    userStatus[user] = UserStatus.Unknown;
}

function checkUserStatus(address user) public view returns (UserStatus) {
    return userStatus[user];
}

           
}
