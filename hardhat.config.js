require('dotenv').config();
require("@nomiclabs/hardhat-waffle");

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
    solidity: "0.8.20",
    networks: {
        goerli: {
            url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY],
        },
    },
};
