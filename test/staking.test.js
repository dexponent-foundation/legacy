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
async function sendETH(address, signer,amount) {
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
  before(async () => {
    [signer, user] = await ethers.getSigners();
    clETH =  await deployProxy("CLETH",signer,"TokenProxy")
    wclETH = await deployProxy("wclETH",signer,"TokenProxy")
    stakingMasterProxy = await deployProxy("StakingMaster",signer,"DexProxy")
    // hre.tracer.nameTags[proxy.address] = "PROXY_MSC_!";
    hre.tracer.nameTags[clETH.address] = "CLETH_!";
    hre.tracer.nameTags[user.address] = "USER_!";
    hre.tracer.nameTags[signer.address] = "OWNER_!";
    hre.tracer.nameTags[NULL_ADDRESS] = "NULL_ADDRESS_!";
  });

  describe("Smart contract function test", async () => {
    it("Init clETH contract", async () => {
      await clETH.initialize(signer.address,stakingMasterProxy.address);
    })
    it("Init clETH contract", async () => {
      await wclETH.initialize("wclETH", "Wcleth");
    })

    it("Init to staking Master contract should be reverted as  we are passing zero address", async () => {
      expect (stakingMasterProxy.setUp(ethers.constants.AddressZero, ethers.constants.AddressZero)).to.be.revertedWith("Address can not be zero")
    })
    it("Init to staking Master contract should be reverted as  we are passing zero address", async () => {
        expect (stakingMasterProxy.setUp(signer.address, ethers.constants.AddressZero)).to.be.revertedWith("Address can not be zero")
      })
      it("Init to staking Master contract", async () => {
        await stakingMasterProxy.setUp(clETH.address, signer.address)
      })
    // it("Greant role to staking master", async () => {
    //   await clETH.grantRoles(stakingMasterProxy.address)
    // })
    it("stake  32 ETH to staking master contract", async () => {
      await stakingMasterProxy.connect(user).stake({ value: DEPOSIT_AMOUNT })
    })

    it("We deposit 32 ETH , User cleth balance should be equal to 32 cleth", async () => {
      const userClethBalance = await clETH.balanceOf(user.address)
      expect(userClethBalance).to.be.equal(DEPOSIT_AMOUNT)
    })
    it("This should be reverted as we are depositing 12 ETH and our min Deposit required is 32 ETH", async () => {
      expect(stakingMasterProxy.connect(user).stake({ value: WRONG_DEPOSIT_AMOUNT })).to.be.revertedWith("Must sent minimum 32 ETH")
    })
  })
  describe("Rewards functions testing", async () => {
    it("sending 0.04 ETH for Rewards to ISC", async () => {
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      await sendETH(userIscAddress, signer,'0.04')
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
    it("Sending ISC ETH to User to check edge case", async () => {
      userISC = await ethers.getContractAt("StakeHolder", USERISC)
     await userISC.connect(signer).sendEth(user.address, DEPOSIT_AMOUNT)
    })   
    it("Claim clETH rewards for users should be reverted as the rewards are not created yet", async () => {
       expect(stakingMasterProxy.connect(signer).claimRewardForCleth(user.address, REWARDS_AMOUNT)).to.be.revertedWith("Insufficient Rewards to claim")
    })
    it("Sending 32 ETH to ISC as our edge case for the Rewards has been tested", async () => {
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      await sendETH(userIscAddress, signer,"32")
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
    it(`While Request unstaking it Should be rejected with error Amount can not be zero as we are sending 0 unstaking amount`, async () => {
      expect(stakingMasterProxy.connect(user).unstake(parseEther("0"))).to.be.revertedWith("Amount can not be zero")
    })
    it("Transfer User cleth To user account from another account as we are done with Edge case ", async () => {
      await clETH.connect(signer).transfer(user.address, DEPOSIT_AMOUNT)
    })

    it("Request Unstaking User deposit from staking Master", async () => {
      await stakingMasterProxy.connect(user).unstake(DEPOSIT_AMOUNT)
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
    it("Claim user ClETH from ISC gave him the staked ETH ", async () => {
      await stakingMasterProxy.burnCleth(user.address, DEPOSIT_AMOUNT)
    })
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
      expect(stakingMasterProxy.connect(signer).updateWithdrawalStatus(signer.address, 0)).to.be.revertedWith("Amount can not be zero")
    })
    it("send ETH to user for testing rewards", async () => {
      userISC = await ethers.getContractAt("StakeHolder", USERISC)
     await userISC.connect(signer).sendEth(user.address, DEPOSIT_AMOUNT)
    })   
     it("claim user's fund and it should be reverted user is withdrawaing amoun that is not in peresent in ISC as of now", async () => {
      expect(stakingMasterProxy.connect(signer).burnCleth(user.address, DEPOSIT_AMOUNT)).to.be.revertedWith("Invalid withdrawal amount")
    })

    it("claim user's fund", async () => {
     await sendETH(USERISC,signer,'0.1')
      expect(stakingMasterProxy.connect(signer).burnCleth(user.address, DEPOSIT_AMOUNT)).to.be.emit("UnstakedDone")
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
    it("call setFigmentDepositor", async () => {
     expect( userISC.connect(signer).setFigmentDepositor(signer.address
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
  })
})