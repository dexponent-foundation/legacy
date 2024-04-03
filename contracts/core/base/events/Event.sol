pragma solidity ^0.8.19;
import "../StakeHolder.sol";

contract Events {
    event Unstaked(address indexed user, uint256 amount);
    event UpdateFigmentDepositAddress(
        address indexed oldAddress,
        address indexed newAddress
    );
    event Staked(
        address indexed user,
        StakeHolder stakeHolderContract,
        uint256 amount
    );
    event UnstakedDone(address indexed user, uint256 amount);
    event WclethRewards(address indexed account, uint256 amount);
    event WithdrawalStatusUpdated(address indexed user, uint256 amount);
    event ClethRewards(address indexed account, uint256 amount);
    event OwnerUpdated(address indexed oldOwner,address indexed newOwner);
        event StakedForWCeth(
        address indexed user,
        StakeHolder stakeHolderContract,
        uint256 amount
    );
}
