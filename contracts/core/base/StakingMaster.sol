// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../token/ClEth.sol";
import "./StakeHolder.sol";
import "hardhat/console.sol";
import {IFigmentEth2Depositor} from "../interfaces/IFigmentEth2Depositor.sol";

contract StakingMaster {
    CLETH clETH;
    IFigmentEth2Depositor public figmentDepositor;
    address public owner;
    uint256 public totalPoolStake;
    mapping(address => StakeHolder) public StakeHolders;
    mapping(address => uint256) public StakedBalance;
    mapping(address => uint256) public WithdrawalBalance;
    event Unstaked(address indexed user, uint256 amount);

    event UnstakedArb(address indexed user, uint256 amount);
    event Staked(
        address indexed user,
        StakeHolder stakeHolderContract,
        uint256 amount
    );
    event StakedForWCelth(
        address indexed user,
        StakeHolder stakeHolderContract,
        uint256 amount
    );
    event UnstakedDone(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsRestaked(address indexed user, uint256 amount);
    event DepositReceived(address indexed depositor, uint256 amount);
    event WithdrawalMade(address indexed receiver, uint256 amount);

    constructor(CLETH _clETH) {
        clETH = _clETH;
        owner = msg.sender;
    }

    function setFigmentDepositor(
        IFigmentEth2Depositor _figmentDepositor
    ) external onlyOwner {
        figmentDepositor = _figmentDepositor;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake() public payable {
        // require(amount > 1e18, "Must send ETH to stake");
        // TODO : add check to deposit 32 ETH
        StakeHolder stakeHolder = StakeHolders[msg.sender];
        stakeHolder = _stake(stakeHolder);
        clETH.mint(address(msg.sender), msg.value);
        emit Staked(msg.sender, stakeHolder, msg.value);
    }

    function stakeForWCLETH() public payable {
        // require(amount > 1e18, "Must send ETH to stake");
        // TODO : add check to deposit 32 ETH
        StakeHolder stakeHolder = StakeHolders[msg.sender];
        stakeHolder = _stake(stakeHolder);
        clETH.mint(address(stakeHolder), msg.value);
        emit StakedForWCelth(msg.sender, stakeHolder, msg.value);
    }

    function _stake(StakeHolder stakeHolder) internal returns (StakeHolder) {
        if (address(stakeHolder) == address(0)) {
            stakeHolder = new StakeHolder{value: msg.value}(
                msg.sender,
                address(this),
                owner,
                figmentDepositor,
                clETH
            );
            StakeHolders[msg.sender] = stakeHolder;
        } else {
            (bool success, ) = address(stakeHolder).call{value: msg.value}("");
            require(success, "Failed to send ETH to StakeHolder");
        }
        StakedBalance[msg.sender] += msg.value;
        totalPoolStake += msg.value;
        return stakeHolder;
    }

    function unstakeWCleth( address account,uint256 amount) public onlyOwner {
        require(amount != 0, "Amount can not be zero");
        require(account != address(0), "Zero address");
        require(StakedBalance[account] >= amount, "Not enough staked ETH");
        StakeHolder stakedHolderContract = StakeHolders[account];
        require( WithdrawalBalance[account] + amount <= clETH.balanceOf(address(stakedHolderContract)), "not enough cleth");
        WithdrawalBalance[account] += amount;
        StakedBalance[account] -= amount;
        totalPoolStake -= amount;
        emit UnstakedArb(account, amount);
    }
    function burnCleth(address account,uint256 amount) external onlyOwner {
        require(account != address(0), "Account is zero address");
        require(amount <= WithdrawalBalance[account],"withdrawalBalance is none");
        StakeHolder stakedHolderContract = StakeHolders[account];
        WithdrawalBalance[account]  -= amount;
        clETH.burn(address(stakedHolderContract), amount);
        stakedHolderContract.withdrawETH(amount,account);
        emit UnstakedDone(account,amount);
    }

    function unstake(uint256 amount) public {
        require(amount != 0, "Amount can not be zero");
        require(StakedBalance[msg.sender] >= amount, "Not enough staked ETH");
        require(clETH.balanceOf(msg.sender) >= amount, "Not enough clETH");
        clETH.transferFrom(
            msg.sender,
            address(StakeHolders[msg.sender]),
            amount
        );
        WithdrawalBalance[msg.sender] += amount;
        StakedBalance[msg.sender] -= amount;
        totalPoolStake -= amount;
        emit Unstaked(msg.sender, amount);
    }
}
