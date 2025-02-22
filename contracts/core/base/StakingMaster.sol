// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../token/ClEth.sol";
import "./StakeHolder.sol";
import {IFigmentEth2Depositor} from "../interfaces/IFigmentEth2Depositor.sol";
import "./StakingMasterStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract StakingMaster is Initializable, StakingMasterStorage, Events{
   function setUp(
      address  _clethToken
    ) public virtual  initializer {
         clETH = CLETH(_clethToken);
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
        require(msg.value >= MAX_DEPOSIT_AMOUNT, "Must send ETH to stake");
        StakeHolder stakeHolder = StakeHolders[msg.sender];
        stakeHolder = _stake(stakeHolder);
        clETH.mint(address(msg.sender), msg.value);
        emit Staked(msg.sender, stakeHolder, msg.value);
    }

    function stakeForWCLETH() public payable {
        require(msg.value >= MAX_DEPOSIT_AMOUNT, "Must send ETH to stake");
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

    function updateWithdrawalStatus(address account, uint256 amount) public onlyOwner {
        require(amount != 0, "Amount can not be zero");
        require(account != address(0), "Zero address");
        require(StakedBalance[account] >= amount, "Not enough staked ETH");
        StakeHolder stakedHolderContract = StakeHolders[account];
        require(
            WithdrawalBalance[account] + amount <=
                clETH.balanceOf(address(stakedHolderContract)),
            "not enough cleth"
        );
        WithdrawalBalance[account] += amount;
        emit withdrawalStatusUpdated(account, amount);
    }

    function burnCleth(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Account is zero address");
        require(
            amount <= WithdrawalBalance[account],
            "withdrawal amount is not enough"
        );
        StakeHolder stakedHolderContract = StakeHolders[account];
        WithdrawalBalance[account] -= amount;
        StakedBalance[account] -= amount;
        totalPoolStake -= amount;
        clETH.burn(address(stakedHolderContract), amount);
        stakedHolderContract.withdrawETH(amount, account);
        emit UnstakedDone(account, amount);
    }

    function claimRewardForCleth(
        address account,
        uint256 amount
    ) external onlyOwner {
        claimReward(account, account, amount);
        emit ClethRewards(account, amount);
    }

    function claimRewardForWcleth(
        address account,
        uint256 amount
    ) external onlyOwner {
        StakeHolder stakeHolder = StakeHolders[account];
        claimReward(address(stakeHolder), account, amount);
        emit WclethRewards(account, amount);
    }

    function claimReward(
        address clETHMintTo,
        address account,
        uint256 amount
    ) internal {
        require(amount > 0, "Zero amount");
        require(account != address(0), "Account is zero address");
        StakeHolder stakeHolder = StakeHolders[account];
        require(address(stakeHolder) != address(0), "Invalid Account");
        require(
            address(stakeHolder).balance >= amount,
            "Insufficient Rewards to claim"
        );
        clETH.mint(clETHMintTo, amount);
        stakeHolder.withdrawETH(amount, stakeHolder.masterContract());
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
        emit Unstaked(msg.sender, amount);
    }
    receive() external payable {} 
}


