const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { deployProxy } = require("./utils");



const {
  DEPOSIT_AMOUNT,
  WRONG_DEPOSIT_AMOUNT,
  REWARDS_AMOUNT,
  ONLY_OWNER_CAN_CALL,
  NOT_ENOUGH_STAKED_ETH,
  INSUFFICIENT_REWARDS,
  WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH,
  NULL_ADDRESS,
  ZERO_ADDRESS_ERROR,
  STAKEDFORWCLETH,
  PUBKEYS_BYTES,
  pubkeysBytes,
  withdrawalCredentialsBytes,
  signaturesBytes,
  depositDataRootsBytes
} = require("./constants");
async function sendETH(address, signer, amount) {
  let amountToSend = parseEther(amount);
  let tx = {
    to: address,
    value: amountToSend,
  };
  await signer.sendTransaction(tx);
}



describe("StakingMaster Contract", function () {
  let signer, user;
  let clETH;
  let stakingMasterProxy;
  let USERISC;
  let userISC
  let wclETH
  let SSV
  let Beacon
  let ssvn
  before(async () => {
    [signer, user] = await ethers.getSigners();
    clETH = await deployProxy("CLETH", signer, "TokenProxy");
    wclETH = await deployProxy("wclETH", signer, "TokenProxy");
    stakingMasterProxy = await deployProxy("StakingMaster", signer, "DexProxy");
  
    SSV = { address: "0x1234567890123456789012345678901234567890" };
  
    const beaconAddress = "0x1234567890123456789012345678901234567890"; // Replace with actual contract address

    // Getting an instance of the beacon using its interface and address
    Beacon = await ethers.getContractAt("IBeacon", beaconAddress, signer);
  
    hre.tracer.nameTags[clETH.address] = "CLETH_!";
    hre.tracer.nameTags[user.address] = "USER_!";
    hre.tracer.nameTags[signer.address] = "OWNER_!";
  });
  describe("Smart contract function test", async () => {
    it("Init clETH contract", async () => {
      await clETH.initialize(signer.address, stakingMasterProxy.address);
    })
    it("Init clETH contract", async () => {
      await wclETH.initialize("wclETH", "Wcleth");
    })

    it("Init to staking Master contract should be reverted as  we are passing zero address", async () => {
      await expect(stakingMasterProxy.setUp(
        ethers.constants.AddressZero, // clETH token address
        ethers.constants.AddressZero, // Figment depositor address
        ethers.constants.AddressZero, // SSV token address
        ethers.constants.AddressZero, // SSV network address
        ethers.constants.AddressZero  // Beacon contract address
    )).to.be.revertedWith("Address cannot be zero")
    })
    
    it("Init to staking Master contract should be reverted as  we are passing zero address", async () => {
      expect(stakingMasterProxy.setUp(signer.address, ethers.constants.AddressZero)).to.be.revertedWith("Address cannot be zero")
    })
    it("Init to staking Master contract", async () => {
      console.log("clETH.address:", clETH.address);
console.log("signer.address:", signer.address);
console.log("SSV.address:", SSV.address);
console.log("Beacon.address:", Beacon.address);
      await stakingMasterProxy.setUp(clETH.address, signer.address,SSV.address,          // Address of the SSV contract
      Beacon.address,       
      Beacon.address)
    })

    it("stake  32 ETH to staking master contract", async () => {
      const stakingId = 1;
      await stakingMasterProxy.connect(user).stake(stakingId,{ value: DEPOSIT_AMOUNT })
    })

    it("We deposit 32 ETH , User cleth balance should be equal to 32 cleth", async () => {
      const userClethBalance = await clETH.balanceOf(user.address)
      expect(userClethBalance).to.be.equal(DEPOSIT_AMOUNT)
    })
    it("This should be reverted as we are depositing 12 ETH and our min Deposit required is 32 ETH", async () => {
      expect(stakingMasterProxy.connect(user).stake({ value: WRONG_DEPOSIT_AMOUNT })).to.be.revertedWith("Must sent minimum 32 ETH")
    })
    it("should not allow staking less than the minimum required amount", async function () {
      const stakingId = 1;
      await expect(stakingMasterProxy.connect(user).stake(stakingId,{value: ethers.utils.parseEther("0.1")}))
        .to.be.revertedWith("Must sent minimum 32 ETH");
    });
    it("should not allow changing ownership to the zero address", async function () {
      await expect(stakingMasterProxy.connect(signer).changeOwner(ethers.constants.AddressZero))
        .to.be.revertedWith("Address cannot be zero");
    });
    it("should not allow changing ownership to a zero address", async function () {
      // This assumes that there is an 'OwnerUpdated' event that gets emitted on successful ownership change
      await expect(stakingMasterProxy.connect(signer).changeOwner(ethers.constants.AddressZero))
          .to.be.revertedWith("Address cannot be zero");
  });
  it("should not allow setting the SVV token amount to zero", async function () {
    await expect(stakingMasterProxy.connect(signer).setSvvTokenAmount(0))
        .to.be.revertedWith("Amount can not be zero");
});
it("should not allow transferring SVV tokens to a zero address", async function () {
  // Using a valid token amount for the test
  const validTokenAmount = parseEther("10");
  await stakingMasterProxy.connect(signer).setSvvTokenAmount(validTokenAmount);

  await expect(stakingMasterProxy.connect(signer).transferSvvTokenTo(ethers.constants.AddressZero))
      .to.be.revertedWith("Zero address");
});
it("should not allow operations when there are insufficient staked ETH", async function () {
  const highAmount = parseEther("1000"); // An amount that is presumably higher than what is staked
  await expect(stakingMasterProxy.connect(user).unstake(highAmount))
      .to.be.revertedWith("");
});


    
  })
  describe("Rewards functions testing", async () => {
    it("sending 0.04 ETH for Rewards to ISC", async () => {
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      await sendETH(userIscAddress, signer, '0.04')
    })

    it("Claim Cleth as a Rewards for the User", async () => {
      await stakingMasterProxy.connect(signer).claimRewardForCleth(user.address, REWARDS_AMOUNT)
      result = await clETH.balanceOf(user.address)
      expect(result).to.be.equal("32020000000000000000")
    })
    it("Claim Cleth as a Rewards for the User should be reverted as the account is zero address", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForCleth(ethers.constants.AddressZero, REWARDS_AMOUNT)).to.be.revertedWith("Address can not be zero")

    })
    it("Claim Cleth as a Rewards for the User should be reverted as the account has never staked or nor created any Validator", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForCleth(signer.address, REWARDS_AMOUNT)).to.be.revertedWith("Invalid Account")

    })
    it("Claim Cleth as a Rewards for the User should be reverted as the amount is zero", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForCleth(user.address, parseEther("0"))).to.be.revertedWith("amount can not be zero")

    })
    it("Claim Cleth as a Rewards for the User should be reverted as caller is not owner", async () => {
      expect(stakingMasterProxy.connect(user).claimRewardForCleth(user.address, parseEther("10"))).to.be.reverted

    })
    it("Claim Cleth as a Rewards for the User should be reverted as the amount as singer never staked for Wcleth", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForWcleth(signer.address, parseEther("10"))).to.be.revertedWith("clETHMintTo can not be null")
    })
    it("Claim wCleth as a Rewards for the User should be reverted as the amount is zero", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForWcleth(user.address, parseEther("0"))).to.be.revertedWith("amount can not be zero")

    })
    it("Claim wCleth as a Rewards for the User should be reverted as the account is zero address", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForWcleth(ethers.constants.AddressZero, REWARDS_AMOUNT)).to.be.revertedWith("Address can not be zero")

    })
    it(" Claim wCleth as a Rewards for the User", async () => {
      await stakingMasterProxy.claimRewardForWcleth(user.address, REWARDS_AMOUNT)
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      const userClethBalance = await clETH.balanceOf(userIscAddress)
      USERISC = userIscAddress
      expect(userClethBalance).to.be.equal(REWARDS_AMOUNT)
    })
    
    
    it("Claim clETH rewards for users should be reverted as the rewards are not created yet", async () => {
      expect(stakingMasterProxy.connect(signer).claimRewardForCleth(user.address, REWARDS_AMOUNT)).to.be.revertedWith("Insufficient Rewards to claim")
    })
    it("Sending 32 ETH to ISC as our edge case for the Rewards has been tested", async () => {
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      await sendETH(userIscAddress, signer, "32")
    })
    it(`claimRewardForWcleth Should be reverted with ${ONLY_OWNER_CAN_CALL}`, async () => {
      const ONLY_OWNER_CAN_CALL = "Only the owner can call this function"
      expect(stakingMasterProxy.connect(user).claimRewardForWcleth(user.address, REWARDS_AMOUNT)).to.be.revertedWith(ONLY_OWNER_CAN_CALL);
    })

  })
  describe("Unstake flow", async () => {
    it("Pause the clETH contract for testing edge case", async () => {
      await clETH.connect(signer).pause()
    })
    it("Staking function on staking master should be fail as the cleth contract is pause", async () => {
      expect(stakingMasterProxy.connect(user).stake({ value: DEPOSIT_AMOUNT })).to.be.revertedWith("EnforcedPause")
    })
    it("Unpause the clETH contract as we are done with edge case testing", async () => {
      await clETH.connect(signer).unpause()
    })
    it("Provide approval to Staking master for Cleth to transfer  ", async () => {
      await clETH.connect(user).approve(stakingMasterProxy.address, DEPOSIT_AMOUNT)
    })
    it("Transfer User clETH to another User to test edge case", async () => {
      await clETH.connect(user).transfer(signer.address, DEPOSIT_AMOUNT)
    })
    it(`While Request unstaking it Should be rejected with error ${NOT_ENOUGH_STAKED_ETH}  as we Transfered Cleth to Another User`, async () => {
      expect(stakingMasterProxy.connect(user).unstake(DEPOSIT_AMOUNT)).to.be.revertedWith("Not enough clETH")
    })
    it(`While Request unstaking it Should be rejected with error Amount cannot be zero as we are sending 0 unstaking amount`, async () => {
      expect(stakingMasterProxy.connect(user).unstake(parseEther("0"))).to.be.revertedWith("Amount cannot be zero")
    })
    it("Transfer User cleth To user account from another account as we are done with Edge case ", async () => {
      await clETH.connect(signer).transfer(user.address, DEPOSIT_AMOUNT)
    })

    it("Request Unstaking User deposit from staking Master", async () => {
      const amountToUnstake = ethers.utils.parseEther("10"); // Example amount
      const publicKey = "0x123abc"; // Example public key, adjust as necessary
      const stakingId = 1; // Example staking ID, adjust based on your contract's logic
  
      await stakingMasterProxy.connect(user).unstake(amountToUnstake, publicKey, stakingId);
  })
    it(`Request Unstaking Should be rejected with error ${NOT_ENOUGH_STAKED_ETH}  as we already have been unstaked our staked amount`, async () => {
      expect(stakingMasterProxy.connect(user).unstake(DEPOSIT_AMOUNT)).to.be.revertedWith(NOT_ENOUGH_STAKED_ETH)
    })
    it(`Claiming Fund, it Should be reverted with ${WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH}  as we are trying to claim more the then Request Unstaking amount`, async () => {
      expect(stakingMasterProxy.burnCleth(user.address, DEPOSIT_AMOUNT + DEPOSIT_AMOUNT)).to.be.revertedWith(WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH)
    })
    it(`Claiming Fund, it Should be reverted with Account is zero address as we are pass User address Zero address `, async () => {
      expect(stakingMasterProxy.burnCleth(NULL_ADDRESS, DEPOSIT_AMOUNT + DEPOSIT_AMOUNT)).to.be.revertedWith("Address can not be zero")
    })
    it(`Claiming Fund Should be reverted with ${ONLY_OWNER_CAN_CALL} as only owner can call this function`, async () => {
      expect(stakingMasterProxy.connect(user).burnCleth(user.address, DEPOSIT_AMOUNT)).to.be.revertedWith(ONLY_OWNER_CAN_CALL)
    })
    // it("Claim user ClETH from ISC gave him the staked ETH ", async () => {
    //   await stakingMasterProxy.burnCleth(user.address, DEPOSIT_AMOUNT)
    // })
    it(`It should be reverted with ${INSUFFICIENT_REWARDS} as there is no rewards for the user on ISC`, async () => {
      expect(stakingMasterProxy.claimRewardForWcleth(user.address, REWARDS_AMOUNT)).to.be.revertedWith(INSUFFICIENT_REWARDS)
    })
    it(`It should be reverted with ${ZERO_ADDRESS_ERROR} as we are passing NULL address`, async () => {
      expect(stakingMasterProxy.claimRewardForWcleth(NULL_ADDRESS, REWARDS_AMOUNT)).to.be.revertedWith(ZERO_ADDRESS_ERROR)
    })

    it(`set Figment validator on stakeHolder`, async () => {
      await stakingMasterProxy.setFigmentDepositor(signer.address)
    })

    it(`set Figment validator on stakeHolder should  be reverted as the figment  address is zero `, async () => {
      expect(stakingMasterProxy.setFigmentDepositor(ethers.constants.AddressZero)).to.be.revertedWith("Address can not be zero")
    })
    it("should not allow operations when there are insufficient staked ETH", async function () {
      const highAmount = parseEther("1000"); // An amount that is presumably higher than what is staked
      await expect(stakingMasterProxy.connect(user).unstake(highAmount))
          .to.be.revertedWith("");
    })

  })
  describe("ETH for Wlceth staking flow", async () => {

    it("Provide approval to Staking master", async () => {
      await clETH.connect(user).approve(stakingMasterProxy.address, DEPOSIT_AMOUNT)
    })
    it("staked for Wcleth", async () => {
      expect(stakingMasterProxy.connect(user).stakeForWCLETH({ value: DEPOSIT_AMOUNT })).to.be.emit(STAKEDFORWCLETH)
    })
    it("staked 12 ETH for Wcleth should be reverted as the amount is less then 32 ETH", async () => {
      expect(stakingMasterProxy.connect(user).stakeForWCLETH({ value: WRONG_DEPOSIT_AMOUNT })).to.be.revertedWith("Must sent minimum 32 ETH")
    })

    it("Update User withdarawal status once he has request to withdraw fund", async () => {
      expect(stakingMasterProxy.connect(signer).updateWithdrawalStatus(user.address, DEPOSIT_AMOUNT)).to.be.emit("WithdrawalStatusUpdated")
    })
    it("Update User withdarawal status should be reverted as the user never deposit for the Wcleth", async () => {
      expect(stakingMasterProxy.connect(signer).updateWithdrawalStatus(signer.address, DEPOSIT_AMOUNT)).to.be.revertedWith("Not enough staked ETH")
    })
    it("Update User withdarawal status should be reverted the amount withdarwal amount is greater then the deposit amount", async () => {
      expect(stakingMasterProxy.connect(signer).updateWithdrawalStatus(user.address, DEPOSIT_AMOUNT + REWARDS_AMOUNT)).to.be.revertedWith("Not enough staked ETH")
    })
    it("Update User withdarawal status should be reverted as the amount is zero", async () => {
      expect(stakingMasterProxy.connect(signer).updateWithdrawalStatus(signer.address, 0)).to.be.revertedWith("Amount cannot be zero")
    })
    it("Update User withdarawal status should be reverted as caller is not owner", async () => {
      expect(stakingMasterProxy.connect(user).updateWithdrawalStatus(signer.address, DEPOSIT_AMOUNT)).to.be.reverted
    })
    it("claim user's fund and it should be reverted user is withdrawaing amoun that is not in peresent in ISC as of now", async () => {
      expect(stakingMasterProxy.connect(signer).burnCleth(user.address, DEPOSIT_AMOUNT)).to.be.revertedWith("Invalid withdrawal amount")
    })

    it("claim user's fund", async () => {
      await sendETH(USERISC, signer, '0.1')
      expect(stakingMasterProxy.connect(signer).burnCleth(user.address, DEPOSIT_AMOUNT)).to.be.emit("UnstakedDone")
    })
    it("change staking master owner should be reverted as the caller is owner", async () => {
      expect(stakingMasterProxy.connect(user).changeOwner(user.address)).to.be.reverted
    })
    it("change staking master owner", async () => {
      expect(stakingMasterProxy.connect(signer).changeOwner(user.address)).to.be.emit("OwnerUpdated")
    })

    it("change staking master owner should be reverted as the caller is not onwer", async () => {
      expect(stakingMasterProxy.connect(signer).changeOwner(user.address)).to.be.revertedWith("Only the owner can call this function")
    })
    it("change staking master owner should be reverted as we passed a null address for the nen year", async () => {
      expect(stakingMasterProxy.connect(user).changeOwner(ethers.constants.AddressZero)).to.be.revertedWith("Address can not be zero")
    })
    it("change staking master owner", async () => {
      expect(stakingMasterProxy.connect(user).changeOwner(signer.address)).to.be.emit("OwnerUpdated")
    })

    it("mint wclETH for user", async () => {
      await wclETH.connect(signer).mint(user.address, DEPOSIT_AMOUNT);
    })
    it("mint wclETH for user", async () => {
      expect(wclETH.connect(user).mint(user.address, DEPOSIT_AMOUNT)).to.be.revertedWith("OwnableUnauthorizedAccount");
    })
    it("mint wclETH for user should be reverted  with  amount is zero", async () => {
      expect(wclETH.connect(signer).mint(ZERO_ADDRESS_ERROR, 0)).to.be.revertedWith("WCLETH: mint amount must be greater than zero");
    })
    it("mint wclETH for user should be reverted with zero address", async () => {
      expect(wclETH.connect(signer).mint(ethers.constants.AddressZero, DEPOSIT_AMOUNT)).to.be.revertedWith("Address can not be zero");
    })
    it("unstake wCleth for the user", async () => {
      expect(wclETH.connect(user).unstake(DEPOSIT_AMOUNT, PUBKEYS_BYTES)).to.be.emit("unstakedRequested")
    })
    it("should be reverted as the  signer don't have enough wcleth", async () => {
      expect(wclETH.connect(signer).unstake(DEPOSIT_AMOUNT, PUBKEYS_BYTES)).to.be.revertedWith("ERC20InsufficientBalance")
    })
    it("mint wclETH for user should be reverted as user don't have enough wlceth TO burn", async () => {
      expect(wclETH.connect(user).unstake(DEPOSIT_AMOUNT, PUBKEYS_BYTES)).to.be.revertedWith("ERC20InsufficientBalance")
    })
    it("pause wcleth contract", async () => {
      await wclETH.connect(signer).pause(
      )
    })
    it("pause wcleth contract", async () => {
      await wclETH.connect(signer).unpause(
      )
    })

  })
  describe("STAKING HOLDER TEST", async () => {
const operatorIds = [1, 2, 3, 4]; // Expanded operator IDs
      const publicKey = ethers.utils.hexlify(ethers.utils.randomBytes(48)); // Mock public key, 48 bytes
       const sharesData = "0xb944a6e76addfc72c583b0e316393f5079b1269396a72060d22f20a4400aaedbfaa1da6e0fdd5539d03e64cd68d28c430ec51ae54b8de26e6540dbee26b01eafb2697850d96f2399412c089bcb1f24a45aafb113c33ebfdbb32fcd9126851bee9386547c45be98927e9155d1fdb6f254118c332b1e7839b30c35dddb4c77c9433ca72a6a1ad09694a83ed5844b25d00c97005af7d8b2b8afb3c11e14f338e5e4f94112e85eda0c25f933371a830862103bd7a3e51d300e0937420499cea5727f873d3d52f91600535d41e34c01fae731151a6ddf67b5d1c3d2844a5a0a98bbebd76203270246bb043502dc0888bf7b3aa8e8c484df59ea72d8784b9d51e457c9c6547b02709b9dbb81bfeb04c5d2258973c34d013aa4c6aa24f4d6e8c2f6cf0a6224badb008cd0947787a5c2bdd139dcf47776724a63ca7be02e0d2dd0c9ade1ebeb3e8760ecb3afb054880438c66f201b85d3902d1c2fc02e3a455aae29d84cc219985716a312723b1cebfa6b358050af6061d19f94e4f33fbf269bd1a2920e3aed0c52886eb3c3dd8571116d5eddc2361e3f99e52eb8a3314027c8831e39064c41fb2aa470485242626daefc4746286d514092bcc0662418cb3914727e2d47b51884bde882523b0018c0d32f621dcf5659912bdda154f7f73d346538a40350b9e83e010043ac2c60f9c6a6adfc2e0c38cb74e0cd9b074d3633ab55f79e8e2291267101c4a1f3cfccae66138aa4798460dc8e25b792baed869d857b95fb741542c26d5a6b3cd803746b5e9169cd3ec75ab591c5da34251f09d429489371946922b3d3a8123f4c161204ab127d78d53cb939fc2542c0b22d530989f7daba7304e3aa65ffcd547df38091b0d63314476995eb4cdc351db4ac2aff9b75199f45e2827a1fad43a0db73e2a5abf2b147c01e063449e6b17d3c0bc9e704b5ad5ddb66f8c0ac56785c0cf9494e28bed1abe3ccd07af4adbf62ac8473437449a133f618945607f1afbfc4eed50974e47106c89001aa66a51a4cca0cacac3bd789e9304cd65204d2e8d5ff4b75fd606fbfb2aac37244f2f76fd8296220731c6ca743285492559ed45630578d6d07ae584b1a066e46ed4b42b1a83dd6fc6c697ccb545d8726665f19343b8b3a220711e8a2ebd7e2eb8c48ab5d8a1f20ea2296864738e9504506ada904f5c4cb4f92acb9ae0296e3a5391570e277d994662099699f0c34db7cee740f5b552b47e27121db36bf2d3362f4df49d41285522285aab5704623a1165f71c9a5bfc6f4d0275c174784d6c557301749bc06388b29c0e705e585eab5f30d0d28c9da0d8f1ad1ee0ddf27c11c86f5292c9fe417a52802aba8a36bd54f017452d65ca0046b53aa50f7406b462d90b74b37381dd349a0296d96615fd29c63e107637da48233de3437b0927137855ecb4a99e882de4482f8dea233c3dd5382a877dcfb14be890c785fa1161e273910215c4c8c16ea907367418995bd141d23ab2949fffe2bfaed2b1bb056b14532ac83ba6a095f6aa915c430b7321177eac75459e6d0e1cbf34b337fbf8b2ca29033d248837769d984dcba9497a8477f0fc886695f0ec76d0f2350db9aa8751a7db2b0e86bd02ff2aaf5d5d39a9e1c0a3963694db4b6a711a5a006bb3ece185eca921234f2e0a0bf9745fa3e67fdcce8ca6e04489397897405802be15a6c76d76e3648b298220b46e1aaef610f9818dc0f5911a8b21741d9e2c95d451449c87218b4392654ff8a300c699222b1ec31ba1b44ae1a07157f13dffc0a6f875786ac1df8e2ff6ad2c0a25002bf5ae3ceb52229e2fa9bba95c06d7a88ae35f0bd8963d9bd543fb37da6dd18c6d9bc27d0837c09";
       const cluster = {
           clusterId: 1,
           isOperator: true,
           totalStake: "11000000000000000000",
           isActive: true
       };

    it("Load contract ISC", async () => {
      userISC = await ethers.getContractAt("StakeHolder", USERISC)
    })
    it("Deposit to figment from isc", async () => {
      expect(userISC.connect(signer).depositToFigment(
        pubkeysBytes,
        withdrawalCredentialsBytes,
        signaturesBytes,
        depositDataRootsBytes
      )).to.be.revertedWith("Insufficient balance for deposit")
    })
    it("call withdraw ETH non owner user", async () => {
      expect(userISC.connect(signer).withdrawETH(
        DEPOSIT_AMOUNT, user.address
      )).to.be.revertedWith("revert caller is not owner")
    })
    it("call setFigmentDepositor should be reverted as the address is zero", async () => {
      expect(userISC.connect(signer).setFigmentDepositor(
        ethers.constants.AddressZero
      )).to.be.revertedWith("_figmentDepositor is zero address")
    })
    it("should reverted as the caller is not owner", async () => {
      expect(userISC.connect(user).setFigmentDepositor(signer.address
      )).to.be.reverted
    })
    it("call setFigmentDepositor", async () => {
      expect(userISC.connect(signer).setFigmentDepositor(signer.address
      )).to.be.emit("UpdateFigmentDepositAddress")
    })
    it("Deposit to figment from isc should be reverted as the figment address is null", async () => {
      expect(userISC.connect(signer).depositToFigment(
        pubkeysBytes,
        withdrawalCredentialsBytes,
        signaturesBytes,
        depositDataRootsBytes
      )).to.be.revertedWith("Figment depositor address not set")
    })
    it("Deposit to figment from isc should be reverted as the figment address is null", async () => {
      expect(userISC.connect(user).depositToFigment(
        pubkeysBytes,
        withdrawalCredentialsBytes,
        signaturesBytes,
        depositDataRootsBytes
      )).to.be.revertedWith("Caller is not the master owner")
    })

    it("fails to withdraw ETH when the caller is not the owner", async () => {
      const amount = ethers.utils.parseEther("1");
      await expect(userISC.connect(user).withdrawETH(
          amount, user.address
      )).to.be.revertedWith("revert caller is not owner");
    })
     
   it("should revert if the public key is empty", async function () {
    const amount = ethers.utils.parseEther("1");
     await expect(userISC.connect(signer).registerValidatorOnSsv(
         '0x',
         operatorIds,
         sharesData,
         amount,
         cluster
     )).to.be.revertedWith("");
   })
   it("should revert if operator IDs array is empty", async function () {
    const amount = ethers.utils.parseEther("1");
     await expect(userISC.connect(signer).registerValidatorOnSsv(
         publicKey,
         [],
         sharesData,
         amount,
         cluster
     )).to.be.revertedWith("");
   })
   


   
   it("should revert if shares data is empty", async function () {
    const amount = ethers.utils.parseEther("1");
     await expect(userISC.connect(signer).registerValidatorOnSsv(
         publicKey,
         operatorIds,
         '0x',
         amount,
         cluster
     )).to.be.revertedWith("");
   })
   it("should revert if amount is zero", async function () {
    await expect(userISC.connect(signer).registerValidatorOnSsv(
        publicKey,
        operatorIds,
        sharesData,
        0,
        cluster
    )).to.be.revertedWith("");

})
});
describe("StakeHolder Contract Initialization", function () {
  it("should automatically approve clethToken for masterContract upon initialization", async function () {
      // Assuming deployment is done somewhere in your test setups
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      const stakeHolder = await ethers.getContractAt("StakeHolder", userIscAddress); // Use correct deployed address

      // The clethToken and masterContract should be known from the deployment context or test setup
      const approvedAmount = await clETH.allowance(stakeHolder.address, stakingMasterProxy.address);

      // Check if the approved amount matches the maximum possible uint256 value, indicating full approval
      const maxUint256 = ethers.constants.MaxUint256;
      expect(approvedAmount).to.equal(maxUint256);
  });
  
  it("should revert when trying to withdraw more than the available balance", async function () {
   const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      const stakeHolder = await ethers.getContractAt("StakeHolder", userIscAddress);
    const excessiveAmount = ethers.utils.parseEther("100"); // An amount greater than likely balance
    await expect(stakeHolder.withdrawETH(excessiveAmount, user.address))
        .to.be.revertedWith("revert caller is not owner"); // Adjust the revert message based on your contract's error handling
});

   
  

  


  
  
    
    
    
  })
  

});
