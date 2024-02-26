require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");
require("hardhat-tracer");
module.exports = {
  solidity: "0.8.20",
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
      //   url: "https://goerli.infura.io/v3/44bc61f9083149c3a96b0d37f08ed8c0",

      //   // url:"https://optimism-goerli.infura.io/v3/2dff452478174fdf8035dc20eadb5667"
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
    // deployments: "./deployments",
    // artifacts: "./artifacts",
    // storageLayouts: ".storage-layouts",
  },
  // sourcify: {
  //   enabled: true
  // }
};

