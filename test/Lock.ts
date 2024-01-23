import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { Address } from "hardhat-deploy/types";
import uniswapABi from './utils/uniswap_abi.json'
import abispytheth from "./utils/test.json"
import erc20_abi  from "./utils/erc20_abi.json"
const snx = require('synthetix');
import wethabi from "./utils/weth_abi.json"
import hre, { ethers } from "hardhat";
import { EvmPriceServiceConnection } from "@pythnetwork/pyth-evm-js";
import { deployContract } from "@nomicfoundation/hardhat-ethers/types";
import { listenerCount } from "process";
const SUSD: Addreass = "0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9";
const FUTURES_MARKET_MANAGER: Address = "0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463";
const UNISWAP_V3_ROUTER: Address = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
const WETH = "0x4200000000000000000000000000000000000006";
const USDC_WHALE = "0x41dda7bE30130cEbd867f439a759b9e7Ab2569e9";
let signer: any;
let deployedContract:any
let asset_price:any
let deployedContract2:any
let provider:any
let priceUpdateData:any
let pythContract :any
let updateFee:any
async function sendETH (address:any){
   let amountToSend = ethers.parseEther('1'); // 0.1 ETH
    let tx = {
    to: address,
    value: amountToSend,
  };

  // Send the transaction
  let txResponse = await signer.sendTransaction(tx);
  console.log(txResponse)


  // Create a transaction object
  tx = {
    to: deployedContract2,
    value: amountToSend,
  };
}
describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    signer = await ethers.getImpersonatedSigner(USDC_WHALE);
    const Account = await ethers.getContractFactory("Account", signer);
    const Account_Contract = await Account.deploy(SUSD, "0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463");
    return Account_Contract;
  }
  before(async () => {
     provider = ethers.provider
     deployedContract = await deployOneYearLockFixture();
    
     deployedContract2 = await  deployOneYearLockFixture()
    hre.tracer.nameTags[SUSD] = "SYNTHSUSD";
    hre.tracer.nameTags[deployedContract2.target] = "SMART MARGIN-2";
    hre.tracer.nameTags[FUTURES_MARKET_MANAGER] = "FUTURES_MARKET_MANAGER";
    hre.tracer.nameTags[deployedContract.target.toString()] = "SMART MARGIN";
  
    hre.tracer.nameTags[UNISWAP_V3_ROUTER] = "UNISWAP_V3_ROUTER";
    hre.tracer.nameTags[WETH] = "WETH";
    hre.tracer.nameTags[signer.address] = "SGINER";
  });

  describe("Deposit and withdrawal", function () {
  it("approving USDC for 1st contract",async()=>{
    const tokenContract0 = new ethers.Contract(
      SUSD,
      erc20_abi.abi, 
      provider
    )
   

    const approvalResponse = await tokenContract0.connect(signer).approve(
    deployedContract.target,
    ethers.parseEther('10000')
    )
  })
  it("get price feed data",async ()=>{
    const connection = new EvmPriceServiceConnection(
      "https://xc-testnet.pyth.network"
    ); // See Price Service endpoints section below for other endpoints
    const priceIds = [
      // You can find the ids of prices at https://pyth.network/developers/price-feed-ids#pyth-evm-testnet
      "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6", // ETH/USD price id in testnet
    ];
    priceUpdateData = await connection.getPriceFeedsUpdateData(priceIds);
    console.log("-------->",priceUpdateData)
    
  })
    it("Deposit SUDC in Contract", async function () {
    
   await deployedContract.modifyAccountMargin(ethers.parseEther("100"))
   

  }) 
  it("approving USDC for 2nd contract",async()=>{
    const tokenContract0 = new ethers.Contract(
      SUSD,
      erc20_abi.abi, 
      provider
    )
   

    const approvalResponse = await tokenContract0.connect(signer).approve(
    deployedContract2.target,
    ethers.parseEther('10000')
    )
  })
    it("Deposit SUDC in Contract", async function () {
    
   await deployedContract2.modifyAccountMargin(ethers.parseEther("100"))
   

  }) 

  // it("WITHDRAW SUDC from Contract", async function () {
    
  //   await deployedContract.modifyAccountMargin(-ethers.parseEther("100"))
 
  //  })

   
});
describe("synthetix oprations for accoount",async()=>{
  it("get asset price",async ()=>{
    asset_price = await deployedContract.getprice('0x2B3bb4c683BFc5239B029131EEf3B1d214478d93')
   console.log("asset_price--------->",asset_price.toString())
 })
  let market:any
  it("get market", async function () {
   market  = await deployedContract.getPerpsV2Market( snx.toBytes32('sETH'))
    })

  
it('send eth to contract',async()=>{
  sendETH("0x1e1da5748641150203c42ee821cfecbcadbc9a45")
  // sendETH("0x2227af48ec971e3c786f3e06064cba455724d6ba")
  // sendETH("0x2b3bb4c683bfc5239b029131eef3b1d214478d93")
  // let amountToSend = ethers.parseEther('1'); // 0.1 ETH

  // // Create a transaction object
  // let tx = {
  //   to: "0xcfa1ea72bf30e467edb6fe399c834c2df7ca12f6",
  //   value: amountToSend,
  // };

  // // Send the transaction
  // let txResponse = await signer.sendTransaction(tx);
  // console.log(txResponse)


  // // Create a transaction object
  // tx = {
  //   to: deployedContract2,
  //   value: amountToSend,
  // };

  // Send the transaction
  //  txResponse = await signer.sendTransaction(tx);
       function sleepFor(sleepDuration:any){
        var now = new Date().getTime();
        while(new Date().getTime() < now + sleepDuration){ 
            /* Do nothing */ 
        }
    }
    
    function sleepThenAct(){
        sleepFor(30000);
        console.log("Hello, JavaScript sleep!");
    }
    
    sleepThenAct()
})


    it("Deposit margin into SETH for account-1 ", async function () {
     await deployedContract.perpsV2ModifyMargin( "0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",ethers.parseEther("80"))
      })
      // it("Deposit margin into SETH for account-2", async function () {
      //   await deployedContract2.perpsV2ModifyMargin( "0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",ethers.parseEther("80"))
      //    })
                
    // it("Create an position on SETH perp account -2 ",async ()=>{
     
    //   await deployedContract2.perpsV2SubmitDelayedOrder("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",-ethers.parseEther("0.01"),ethers.parseEther("1646.58"))

    // })
     
    it("Create an position on SETH perp",async ()=>{

      await deployedContract.perpsV2SubmitDelayedOrder("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",ethers.parseEther("0.1"),ethers.parseEther("1646.58"))
    })
    // it("get updated price",async ()=>{
    //   pythContract =  new ethers.Contract(
    //     "0xff1a0f4744e8582DF1aE09D5611b887B6a12925C",
    //     abispytheth.abi, 
    //     signer
    //   )
    //   console.log(pythContract)
    //    updateFee = await pythContract.methods
    //   .getUpdateFee(priceUpdateData)
    //   .call();
    //   console.log("fee---->",updateFee)
    // })
   it("excute order",async()=>{
    const balance = await provider.getBalance(signer.address);
    console.log("data balance",balance)
    await deployedContract.excuteOrder("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",priceUpdateData,{value: ethers.parseEther("0.8") })
   })
    // it("getDelayedOrder on SETH perp for account -1 ",async ()=>{
      
    //   const position =  await deployedContract.getDelayedOrder("0x7345544850455250000000000000000000000000000000000000000000000000");
    //   console.log("position:--->",position.toString())
    //  })

    //  it("get position on SETH perp account--2",async ()=>{
    //   const position =  await deployedContract2.getDelayedOrder("0x7345544850455250000000000000000000000000000000000000000000000000");
    //    console.log("position:--->",position.toString())
    //  })
    //  it("excute order 2",async()=>{
    //   await deployedContract2.excuteOrder("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93",priceUpdateData,{value: ethers.parseEther("0.2") })
    //  })
    //  it("cancel DelayedOrder",async ()=>{
    //   function sleepFor(sleepDuration:any){
    //     var now = new Date().getTime();
    //     while(new Date().getTime() < now + sleepDuration){ 
    //         /* Do nothing */ 
    //     }
    // }
    
    // function sleepThenAct(){
    //     sleepFor(30000);
    //     console.log("Hello, JavaScript sleep!");
    // }
    
    // sleepThenAct()

    //   const position =  await deployedContract.perpsV2CancelDelayedOrder("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93");
    //    console.log("position:--->",position.toString())
    //  })

     it("get position on SETH perp for account -2 ",async ()=>{
    
    
    
      const position =  await deployedContract2.getPosition("0x7345544850455250000000000000000000000000000000000000000000000000");
       console.log("position:--->",position.toString())
     })
    //  it("minimum margin required",async ()=>{
    //   const position =  await deployedContract.minMargin("0x2B3bb4c683BFc5239B029131EEf3B1d214478d93");
    //    console.log("position:--->",position.toString())
    // //  })
    //       it("Withdaraw margin into SETH", async function () {
    //     await deployedContract.perpsV2WithdrawAllMargin( "0x2B3bb4c683BFc5239B029131EEf3B1d214478d93")
    //      })
})
});
