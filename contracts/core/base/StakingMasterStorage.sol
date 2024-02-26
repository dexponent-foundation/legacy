// SPDX-License-Identifier: MIT

pragma solidity =0.8.20;
import "../token/ClEth.sol";
import {IFigmentEth2Depositor} from "../interfaces/IFigmentEth2Depositor.sol";
import "./StakeHolder.sol";
import "./events/Event.sol";

abstract contract StakingMasterStorage {


    CLETH public clETH;
    uint256 constant MAX_DEPOSIT_AMOUNT = 32 ether;
    IFigmentEth2Depositor public figmentDepositor;
    address public owner;
    uint256 public totalPoolStake;
    mapping(address => StakeHolder) public StakeHolders;
    mapping(address => uint256) public StakedBalance;
    mapping(address => uint256) public WithdrawalBalance;
    mapping(address => uint256) public totalRewardsClaimed;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __dex_gap;
}