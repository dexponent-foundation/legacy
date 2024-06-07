// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StakeHolder.sol";
import "../interfaces/IFigmentEth2Depositor.sol";
/**
 msg.sender,
                address(this),
                owner,
                address(figmentDepositor),
                address(clETH),
                ssvNetwork,
                beaconContract,
                ssvToken

 */
contract StakeHolderFactory {

    /**
    */
    
    function createStakeHolder(
        address depositor,
        address masterContract,
        address owner,
        IFigmentEth2Depositor figmentDepositor,
        IERC20 clETH,
        address ssvNetwork,
        address beaconContract,
        address ssvToken
    ) public payable returns (StakeHolder) {
        return new StakeHolder{value: msg.value}(
            depositor,
            masterContract,
            owner,
            figmentDepositor,
            clETH,
            ssvNetwork,
            beaconContract,
            ssvToken
        );
    }
}

/**

// stakeHolder = new StakeHolder{value: msg.value}(
            //     msg.sender,
            //     address(this),
            //     owner,
            //     figmentDepositor,
            //     clETH,
            //     ssvNetwork,
            //     beaconContract,
            //     ssvToken
            // ); */
