require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");
require("hardhat-tracer");
require("hardhat-storage-layout");
require("hardhat-storage-layout-changes");
require("hardhat-gas-reporter");
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            runs: 200,
            enabled: true,
          },
          "outputSelection": {
            "*": {
              "*": [
                "metadata", "evm.bytecode" // Enable the metadata and bytecode outputs of every single contract.
                , "evm.bytecode.sourceMap", // Enable the source map output of every single contract.
                "storageLayout"
              ],
              "": [
                "ast" // Enable the AST output of every single file.
              ]
            },
          },
        },
      },
    ]},
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: {
        accountsBalance: "100000000000000000000000000000000000000000",
        accounts: process.env.PRIVATE_KEY || DEFAULT_MNEMONIC,
      },
      // chainId: 5,

      // forking: {
      //   url: "https://goerli.infura.io/v3/",

      //   // url:"https://optimism-goerli.infura.io/v3/"
      // },
    },
    
  },
  georli: {
    url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
    accounts: [process.env.PRIVATE_KEY],
  },

  etherscan: {
    apiKey: process.env.POLYGON_API_KEY,
  },
  paths: {
    tests: "./test",
    cache: "./cache",
    deploy: "./src/deploy",
    sources: "./contracts",
    deployments: "./deployments",
    artifacts: "./artifacts",
    storageLayouts: ".storage-layouts",
  },
  storageLayoutConfig: {
    contracts: ["StakingMaster"],
    fullPath: false
  },

  gasReporter: {
      enabled: (process.env.REPORT_GAS) ? true : false,  
    currency: "USD",
    gasPrice: 10,
  },

};

