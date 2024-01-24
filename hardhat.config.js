require('dotenv').config();
require("@nomiclabs/hardhat-waffle");



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
      },
        // goerli: {
        //     url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
        //     accounts: [PRIVATE_KEY],
        // },
    },
};
