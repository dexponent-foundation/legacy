// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../token/ClEth.sol";
import "./StakeHolder.sol";
import "hardhat/console.sol";
import { IFigmentEth2Depositor } from "../interfaces/IFigmentEth2Depositor.sol";

/**
 * User deposit in contract.
 *  Mint a CLETH and locked it on Staking Master.
 * Mint an WCLETH on Arbitrume.
 *
 */

contract StakingMaster {
  address public owner;
  CLETH clETH;
  IFigmentEth2Depositor public figmentDepositor;
  mapping(address => StakeHolder) public stakeHolders;
  uint256 public totalPoolStake;
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

    StakeHolder stakeHolder = stakeHolders[msg.sender];
    if (address(stakeHolder) == address(0)) {
      // Pass the correct number of arguments to the StakeHolder constructor
      stakeHolder = new StakeHolder{ value: msg.value }(
        msg.sender,
        address(this),
        figmentDepositor,
        clETH
      );
      stakeHolders[msg.sender] = stakeHolder;
    } else {
      (bool success, ) = address(stakeHolder).call{ value: msg.value }("");
      require(success, "Failed to send ETH to StakeHolder");
    }
    stakedBalance[msg.sender] += msg.value;
    totalPoolStake += msg.value;
    clETH.mint(address(stakeHolder), msg.value);
    emit Staked(msg.sender, stakeHolder, msg.value);
  }
  //   function unstake(uint256 amount, address validator) public {
  //     require(amount != 0, "Amount can not be zero");
  //     require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
  //     require(clETH.balanceOf(msg.sender) >= amount, "Not enough clETH");
  //     clETH.burn(msg.sender, amount);
  //     stakedBalance[msg.sender] -= amount;
  //     totalPool -= amount;
  //     StakeHolder user = stakeHolders[msg.sender];
  //     emit Unstaked(msg.sender, amount);
  //   }
}
