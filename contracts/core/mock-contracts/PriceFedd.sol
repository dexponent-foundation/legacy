// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockAggregatorV3 is AggregatorV3Interface {
    int256 private price;
    uint8 private decimalsValue;
    uint256 private latestTimestamp;

    constructor(int256 _initialPrice, uint256 _decimalsValue) {
        price = _initialPrice;
        decimalsValue = uint8(_decimalsValue);
        latestTimestamp = block.timestamp; // Initialize with deployment timestamp
    }

    function setLatestPrice(int256 _price, uint256 _timestamp) public {
        price = _price;
        latestTimestamp = _timestamp; // Set the latest timestamp for the price update
    }

    // Implementing the functions from the AggregatorV3Interface
    function decimals() external view override returns (uint8) {
        return decimalsValue;
    }

    function description() external pure override returns (string memory) {
        return "MockAggregatorV3";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, price, latestTimestamp, latestTimestamp, 0);
    }
}
