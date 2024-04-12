// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../token/ClEth.sol";
import {IFigmentEth2Depositor} from "../interfaces/IFigmentEth2Depositor.sol";
import "./StakeHolder.sol";
import "./events/Event.sol";

/**
 * @title StakingMasterStorage
 * @dev The StakingMasterStorage contract defines storage variables and mappings
 * used by the StakingMaster contract and its related components.
 * It includes details such as clETH token, minimum deposit amount, Figment Eth2 Depositor,
 * owner address, total pool stake, stakeholder mappings, withdrawal balances,
 * and total rewards claimed.
 */
abstract contract StakingMasterStorage {
    CLETH public clETH; // The clETH token contract
    uint256 constant MIN_DEPOSIT_AMOUNT = 32 ether; // Minimum deposit amount required
    IFigmentEth2Depositor public figmentDepositor; // The Figment Eth2 Depositor contract
    address public owner; // The owner address of the contract
    address ssvNetwork;
    address ssvToken;
    uint256 public totalPoolStake; // Total pool stake accumulated
    uint256 ssvTokenAmount;
    mapping(address => StakeHolder) public StakeHolders; // Mapping of staker addresses to their respective StakeHolder contracts
    mapping(address => uint256) public StakedBalance; // Mapping of staker addresses to their staked balances
    mapping(address => uint256) public WithdrawalBalance; // Mapping of staker addresses to their withdrawal balances
    mapping(address => uint256) public totalRewardsClaimed; // Mapping of staker addresses to their total rewards claimed
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __dex_gap;
}
