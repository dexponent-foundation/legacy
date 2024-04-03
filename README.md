# Dexponent Platform

Dexponent is a platform tailored for institutions in the blockchain space. It offers unique solutions focusing on clean staking, segregation of funds, and liquid staking tokens. This README provides an overview of the platform and commands for managing the project.

## Key Features

1. **Clean Staking:**
   - Dexponent prioritizes compliance with global regulations, fostering trust and confidence among institutional investors.

2. **Segregation of Funds:**
   - Funds are strictly segregated across smart contracts, enhancing transparency and minimizing risks associated with commingled funds.

3. **Liquid Staking Token:**
   - Dexponent offers clETH on Ethereum and wclETH on Arbitrum, providing instant liquidity to institutions participating in staking activities.

## Whitepaper

For detailed implementation details and technical specifications, please refer to the [whitepaper](https://docs.dexponent.xyz/).

## Repository Details

## Folder Structure

The project directory includes the following folders and files:
- contracts
  - core
    - base
      - LoanLogic.sol
      - LoanStorage.sol
      - StakeHolder.sol
      - StakingMaster.sol
      - StakingMasterStorage.sol
      - events
        - Event.sol
      - storage
        - TokenStorage.sol
    - interfaces
      - IFigmentEth2Depositor.sol
    - mock-contracts
      - PriceFeed.sol
      - Usdc.sol
    - proxy
      - Proxy.sol
      - TokenProxy.sol
      - interfaces
        - IProxyUpgrade.sol
    - token
      - ClEth.sol
      - WClETH.sol
- hardhat.config.js
- package.json
- slither.config.json
- src
  - deploy
    - deploy.js
- test
  - constants.js
  - loan.test.js
  - staking.test.js
  - utils.js
- yarn.lock

## Installation

Before running the application, ensure you have Node.js version 16 or higher installed on your system. Follow these steps to configure your environment:

1. Create a file named `.env` in the root directory of the project.
2. Copy and paste the following variables into the `.env` file:

    ```plaintext
    MNEMONIC=
    PRIVATE_KEY=
    REPORT_GAS=true
    ```

   **Note:** Make sure to replace the placeholder values with your actual mnemonic, private key, Infura API key, and Polygon API key.


## Obtaining Required Environment Variables

To configure the environment for this project, you'll need to obtain the following environment variables:

##### MNEMONIC
- **Description**: A 12 or 24-word phrase used as a seed for generating cryptographic keys.
- **How to Obtain**: Generate a new mnemonic using a wallet application like MetaMask or Trust Wallet. Look for the option to reveal the mnemonic in the wallet settings.

##### PRIVATE_KEY
- **Description**: Cryptographic key providing access to your cryptocurrency assets.
- **How to Obtain**: Export the private key associated with your wallet from MetaMask or a similar wallet. Be cautious when handling private keys, as they grant full access to your funds.

Once you have obtained these values, you can populate the `.env` file in the root directory of your project with the appropriate values for each variable. Ensure to keep this file secure and avoid sharing it publicly, as it contains sensitive information related to your project's configuration and access credentials.

## Getting Started

To get started with the project, follow these steps:

1. Install dependencies using `yarn install`.
2. Compile smart contracts with `yarn build`.
3. Run tests using `yarn test`.
4. Check test coverage with `yarn coverage`.
