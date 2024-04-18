// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../token/ClEth.sol";
import "./StakeHolder.sol";
import {IFigmentEth2Depositor} from "../interfaces/IFigmentEth2Depositor.sol";
import "./StakingMasterStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./modifier/modifier.sol";
/**
 * @title StakingMaster
 * @dev StakingMaster contract facilitates the staking and unstaking of ETH for clETH tokens, as well as claiming rewards.
 * It interacts with the ClEth token contract, the StakeHolder contract, and the FigmentEth2Depositor interface.
 * The contract is upgradeable and implements the ReentrancyGuardUpgradeable to prevent reentrancy attacks.
 */

contract StakingMaster is
    Initializable,
    ReentrancyGuardUpgradeable,
    StakingMasterStorage,
    Events,
    Modifiers
{
    using Math for uint256;

    /**
     * @dev Initializes the contract with the given ClETH token address and FigmentEth2Depositor address.
     * @param _clethToken The address of the ClEth token contract.
     * @param _figmentDepositor The address of the FigmentEth2Depositor contract.
     */
    function setUp(
        address _clethToken,
        address _figmentDepositor,
        address _ssvToken,
        address _ssvNetowrk,
        address _beaconContract
    )
        public
        virtual
        initializer
        ZeroAddress(_clethToken)
        ZeroAddress(_figmentDepositor)
    {
        clETH = CLETH(_clethToken);
        owner = msg.sender;
        ssvToken = _ssvToken;
        ssvNetwork = _ssvNetowrk;
        beaconContract = _beaconContract;
        figmentDepositor = IFigmentEth2Depositor(_figmentDepositor);
        __ReentrancyGuard_init();
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier to allow only the owner to call certain functions.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /**
     * @dev Sets the FigmentEth2Depositor contract address. Only the owner can call this function.
     * @param _figmentDepositor The address of the new FigmentEth2Depositor contract.
     */
    function setFigmentDepositor(
        IFigmentEth2Depositor _figmentDepositor
    ) external onlyOwner ZeroAddress(address(_figmentDepositor)) {
        emit UpdateFigmentDepositAddress(
            address(figmentDepositor),
            address(_figmentDepositor)
        );
        figmentDepositor = _figmentDepositor;
    }

    /**
     * @dev Allows users to stake ETH for clETH tokens.
     */
    function stake(uint256 stakingId) public payable nonReentrant {
        StakeHolder stakeHolder = _stake();
        clETH.mint(address(msg.sender), msg.value);
        emit Staked(msg.sender, stakeHolder, msg.value, stakingId);
    }

    /**
     * @dev Allows users to stake ETH for WclETH tokens.
     */
    function stakeForWCLETH(uint256 stakingId) public payable nonReentrant {
        StakeHolder stakeHolder = _stake();
        clETH.mint(address(stakeHolder), msg.value);
        emit StakedForWCelth(msg.sender, stakeHolder, msg.value, stakingId);
    }

    /**
     * @dev Internal function to handle the staking process.
     * @return The updated StakeHolder contract.
     */
    function _stake() internal returns (StakeHolder) {
        require(msg.value >= MIN_DEPOSIT_AMOUNT, "Must sent minimum 32 ETH");
        StakeHolder stakeHolder = StakeHolders[msg.sender];
        if (address(stakeHolder) == address(0)) {
            stakeHolder = new StakeHolder{value: msg.value}(
                msg.sender,
                address(this),
                owner,
                figmentDepositor,
                clETH,
                ssvNetwork,
                beaconContract
            );

            StakeHolders[msg.sender] = stakeHolder;
        } else {
            (bool success, ) = address(stakeHolder).call{value: msg.value}("");
            require(success, "Failed to send ETH to StakeHolder");
        }
        IERC20(ssvToken).transfer(address(stakeHolder), ssvTokenAmount);
        StakedBalance[msg.sender] += msg.value;
        totalPoolStake += msg.value;
        return stakeHolder;
    }

    /**
     * @dev Allows a user to unstake a specified amount of ETH.
     * @param amount The amount of ETH to unstake.
     */
    function unstake(
        uint256 amount,
        bytes calldata publicKey,
        uint256 stakingId
    ) public nonReentrant ZeroAmount(amount) {
        bool enoughStaked = hasEnoughStakedETH(amount, msg.sender);
        require(
            enoughStaked && clETH.balanceOf(msg.sender) >= amount,
            "Not enough clETH"
        );
        clETH.transferFrom(
            msg.sender,
            address(StakeHolders[msg.sender]),
            amount
        );
        WithdrawalBalance[msg.sender] += amount;
        emit Unstaked(msg.sender, publicKey, amount, stakingId);
    }
    /**
     * @dev Burns clETH tokens for a given account and withdraws ETH.
     * @param account The address of the account to burn clETH tokens and withdraw ETH for.
     * @param amount The amount of clETH tokens to burn and withdraw ETH for.
     */
    function burnCleth(
        address account,
        uint256 amount
    ) external nonReentrant onlyOwner ZeroAddress(account) ZeroAmount(amount) {
        require(
            amount <= WithdrawalBalance[account],
            "withdrawal amount is not enough"
        );
        StakeHolder stakedHolderContract = StakeHolders[account];
        WithdrawalBalance[account] -= amount;
        StakedBalance[account] -= amount;
        totalPoolStake -= amount;
        clETH.burnFrom(address(stakedHolderContract), amount);
        stakedHolderContract.withdrawETH(amount, account);
        emit UnstakedDone(account, amount);
    }

    /**
     * @dev Updates the withdrawal status for a given account.
     * @param account The address of the account to update the withdrawal status for.
     * @param amount The amount of ETH to update the withdrawal status with.
     */
    function updateWithdrawalStatus(
        address account,
        uint256 amount
    ) public nonReentrant onlyOwner ZeroAddress(account) ZeroAmount(amount) {
        bool enoughStaked = hasEnoughStakedETH(amount, account);
        StakeHolder stakedHolderContract = StakeHolders[account];
        require(
            enoughStaked &&
                WithdrawalBalance[account] + amount <=
                clETH.balanceOf(address(stakedHolderContract)),
            "not enough cleth on staking holder"
        );
        WithdrawalBalance[account] += amount;
        emit WithdrawalStatusUpdated(account, amount);
    }

    /**
     * @dev Claims rewards for a given account using clETH tokens.
     * @param account The address of the account to claim rewards for.
     * @param amount The amount of rewards to claim using clETH tokens.
     */
    function claimRewardForCleth(
        address account,
        uint256 amount
    ) external nonReentrant onlyOwner {
        claimReward(account, account, amount);
        emit ClethRewards(account, amount);
    }

    /**
     * @dev Claims rewards for a given account using wrapped clETH tokens (WCLETH).
     * @param account The address of the account to claim rewards for.
     * @param amount The amount of rewards to claim using wrapped clETH tokens.
     */
    function claimRewardForWcleth(
        address account,
        uint256 amount
    ) external nonReentrant onlyOwner {
        StakeHolder stakeHolder = StakeHolders[account];
        claimReward(address(stakeHolder), account, amount);
        emit WclethRewards(account, amount);
    }

    /**
     * @dev Internal function to claim rewards for a given account.
     * @param clETHMintTo The address to mint clETH tokens to.
     * @param account The address of the account to claim rewards for.
     * @param amount The amount of rewards to claim.
     */
    function claimReward(
        address clETHMintTo,
        address account,
        uint256 amount
    )
        internal
        ZeroAddress(account)
        ZeroAddress(clETHMintTo)
        ZeroAmount(amount)
    {
        StakeHolder stakeHolder = StakeHolders[account];
        require(address(stakeHolder) != address(0), "Invalid Account");
        require(
            address(stakeHolder).balance >= amount,
            "Insufficient Rewards to claim"
        );
        clETH.mint(clETHMintTo, amount);
        stakeHolder.withdrawETH(amount, stakeHolder.masterContract());
    }

    /**
     * @dev Internal function to check if the user has enough staked ETH.
     * @param amount The amount to check against the user's staked ETH.
     * @return enoughStaked A boolean indicating whether the user has enough staked ETH.
     */
    function hasEnoughStakedETH(
        uint256 amount,
        address account
    ) internal view returns (bool enoughStaked) {
        uint256 stakedAmount = StakedBalance[account];
        (, uint256 leftStaked) = stakedAmount.trySub(
            WithdrawalBalance[account]
        );
        require(
            leftStaked > 0 && leftStaked >= amount,
            "Not enough staked ETH"
        );
        enoughStaked = true;
    }

    /**
     * @dev Changes the owner of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(
        address newOwner
    ) external nonReentrant onlyOwner ZeroAddress(newOwner) {
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    function setSvvTokenAmount(uint256 newAmount) external onlyOwner {
        require(newAmount != 0, "Amount can not be zero");
        emit SsvTokenAmountUpdate(ssvTokenAmount, newAmount);
        ssvTokenAmount = newAmount;
    }

    function transferSvvTokenTo(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        StakeHolder stakeHolder = StakeHolders[account];
        require(address(stakeHolder) != address(0), "Invalid Account");
        IERC20(ssvToken).transfer(address(stakeHolder), ssvTokenAmount);
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
