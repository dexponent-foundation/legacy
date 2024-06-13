// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StakingMaster.sol"; 
contract Migration {
    address public oldContractAddress;
    address public newContractAddress;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _oldContractAddress, address _newContractAddress) {
        oldContractAddress = _oldContractAddress;
        newContractAddress = _newContractAddress;
        admin = msg.sender;
    }

    function migrate() public onlyAdmin {
        OldStakingMaster oldContract = OldStakingMaster(oldContractAddress);
        StakingMaster newContract = StakingMaster(newContractAddress);

        uint256 totalStakers = oldContract.totalStakers();
        for (uint256 i = 0; i < totalStakers; i++) {
            address staker = oldContract.stakerAtIndex(i);
            uint256 balance = oldContract.stakerBalance(staker);
            newContract.migrateStakeHolder(staker, balance);
        }
    }
}

interface OldStakingMaster {
    function totalStakers() external view returns (uint256);
    function stakerAtIndex(uint256 index) external view returns (address);
    function stakerBalance(address staker) external view returns (uint256);
}
