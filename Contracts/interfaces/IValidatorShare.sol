// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IValidatorShare {



    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256 amountToDeposit);

    function restake() external returns (uint256, uint256);

    function sellVoucher(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function withdrawRewards() external;

    function migrateOut(address user, uint256 amount) external;

    function migrateIn(address user, uint256 amount) external;

    function unstakeClaimTokens() external;

    function slash(
        uint256 validatorStake,
        uint256 delegatedAmount,
        uint256 totalAmountToSlash
    ) external returns (uint256);

    function updateDelegation(bool _delegation) external;

    function drain(
        address token,
        address payable destination,
        uint256 amount
    ) external;

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;

    // Add any additional functions from the contract here
}
