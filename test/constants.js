const { ethers } = require("ethers");

const DEPOSIT_AMOUNT = ethers.utils.parseEther("32");
const WRONG_DEPOSIT_AMOUNT = ethers.utils.parseEther("12");
const REWARDS_AMOUNT = ethers.utils.parseEther("0.02");
const ONLY_OWNER_CAN_CALL = "Only the owner can call this function";
const NOT_ENOUGH_STAKED_ETH = "Not enough staked ETH";
const INSUFFICIENT_REWARDS = "Insufficient Rewards to claim";
const WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH = "Withdrawal amount is not enough";
const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_ADDRESS_ERROR = "Account is zero address";
const UNAUTHORIZEDACCOUNT = "AccessControlUnauthorizedAccount";
const STAKEDFORWCLETH = "StakedForWCleth";
const TESTPUBKEY = "0x123456";
const PUBKEYS_BYTES = "0xa2d74fca1f4cef3ab70a856fd1ff74081854d45df279dec4c92a65d27522263f1053ea0953de3f0f4e203d6002507e7d";

const pubkeysBytes = [ethers.utils.arrayify("0xa2d74fca1f4cef3ab70a856fd1ff74081854d45df279dec4c92a65d27522263f1053ea0953de3f0f4e203d6002507e7d")];
const withdrawalCredentialsBytes = [ethers.utils.arrayify("0x01000000000000000000000087d970953323b1d34fbe7dc4787c5a77ef006669")];
const signaturesBytes = [ethers.utils.arrayify("0xb9254ed04514a3841444b6ca5c74dc7048724081dc401f49fcc811e625526764228714f1b41b4b61c8cc18876dee032918b3b631da73ea52a3fcd396bccd3c67292f5211f23f10f50b6bb5ff650d4e5413be05fb76bffd4ceb6ea6e74b67aee6")];
const depositDataRootsBytes = [ethers.utils.arrayify("0x1274da0d6f4b351c8537f164a833269dc23cbab1bd39235c33dc7aa42c37c589")];

module.exports = {
    DEPOSIT_AMOUNT,
    WRONG_DEPOSIT_AMOUNT,
    REWARDS_AMOUNT,
    ONLY_OWNER_CAN_CALL,
    NOT_ENOUGH_STAKED_ETH,
    INSUFFICIENT_REWARDS,
    WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH,
    NULL_ADDRESS,
    ZERO_ADDRESS_ERROR,
    UNAUTHORIZEDACCOUNT,
    STAKEDFORWCLETH,
    TESTPUBKEY,
    PUBKEYS_BYTES,
    pubkeysBytes,
    withdrawalCredentialsBytes,
    signaturesBytes,
    depositDataRootsBytes
};
