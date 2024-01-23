// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {IERC20} from "../interface/token/IERC20.sol";
import {IFuturesMarketManager} from "../interface/IFuturesMarketManager.sol";
import {IPerpsV2MarketConsolidated} from "../interface/IPerpsV2MarketConsolidated.sol";
import "hardhat/console.sol";
import {IOps} from "../interface/gelato/IOps.sol";
import {IAccount} from "../interface/IAccount.sol";
import {IEvents} from "../interface/IEvents.sol";
import {OpsReady} from "../interface/gelato/OpsReady.sol";
import {ISystemStatus} from "../interface/ISystem.sol";
import {IPerpsV2ExchangeRate} from "../interface/IPerpsV2ExchangeRate.sol";

contract Account is IAccount, OpsReady {
    receive() external payable {
        // You can add custom logic here if needed
    }

    IERC20 internal immutable MARGIN_ASSET;
    address owner;
    IEvents internal immutable EVENTS;
    IFuturesMarketManager internal immutable FUTURES_MARKET_MANAGER;
    IPerpsV2ExchangeRate internal immutable PERPS_V2_EXCHANGE_RATE;
    ISystemStatus internal immutable SYSTEM_STATUS;

    uint256 internal constant MAX_PRICE_LATENCY = 120;
    bytes32 internal constant TRACKING_CODE = "KWENTA";
    uint256 public committedMargin;
    /// @inheritdoc IAccount
    uint256 public conditionalOrderId;
    uint256 public executorFee = 1 ether / 1000;
    /// @notice track conditional orders by id
    mapping(uint256 id => ConditionalOrder order) internal conditionalOrders;

    constructor(
        AccountConstructorParams memory _params
    ) OpsReady(_params.gelato, _params.ops) {
        // FACTORY = IFactory(_params.factory);
        EVENTS = IEvents(_params.events);
        MARGIN_ASSET = IERC20(_params.marginAsset);
        PERPS_V2_EXCHANGE_RATE = IPerpsV2ExchangeRate(
            _params.perpsV2ExchangeRate
        );
        FUTURES_MARKET_MANAGER = IFuturesMarketManager(
            _params.futuresMarketManager
        );
        SYSTEM_STATUS = ISystemStatus(_params.systemStatus);
        // SETTINGS = ISettings(_params.settings);
        // UNISWAP_UNIVERSAL_ROUTER = IUniversalRouter(_params.universalRouter);
        // PERMIT2 = IPermit2(_params.permit2);
    }

    function freeMargin() public view returns (uint256) {
        return MARGIN_ASSET.balanceOf(address(this)) - committedMargin;
    }

    function modifyAccountMargin(int256 _amount) external {
        if (_amount > 0) {
            MARGIN_ASSET.transferFrom(msg.sender, address(this), _abs(_amount));
        } else if (_amount < 0) {
            _sufficientMargin(_amount);

            MARGIN_ASSET.transfer(msg.sender, _abs(_amount));
        }
    }

    function perpsV2CancelDelayedOrder(address _market) external {
        IPerpsV2MarketConsolidated(_market).cancelOffchainDelayedOrder(
            address(this)
        );
    }

    function getDelayedOrder(
        bytes32 _marketKey
    )
        external
        view
        returns (IPerpsV2MarketConsolidated.DelayedOrder memory order)
    {
        // fetch delayed order data from Synthetix
        order = getPerpsV2Market(_marketKey).delayedOrders(address(this));
    }

    function getMarkeetKey(address _market) external returns (bytes32) {
        return IPerpsV2MarketConsolidated(_market).marketKey();
    }

    function getAssetPrice(
        address _market
    ) external returns (uint price, bool invalid) {
        return IPerpsV2MarketConsolidated(_market).assetPrice();
    }

    function perpsV2ModifyMargin(address _market, int256 _amount) public {
        if (_amount > 0) {
            _sufficientMargin(_amount);
        }

        IPerpsV2MarketConsolidated(_market).transferMargin(_amount);
    }

    function _placeConditionalOrder(
        bytes32 _marketKey,
        int256 _marginDelta,
        int256 _sizeDelta,
        uint256 _targetPrice,
        ConditionalOrderTypes _conditionalOrderType,
        uint256 _desiredFillPrice,
        bool _reduceOnly
    ) internal {
        if (_sizeDelta == 0) revert ZeroSizeDelta();

        // if more margin is desired on the position we must commit the margin
        if (_marginDelta > 0) {
            _sufficientMargin(_marginDelta);
            committedMargin += _abs(_marginDelta);
        }

        // create and submit Gelato task for this conditional order
        bytes32 taskId = _createGelatoTask();

        // internally store the conditional order
        conditionalOrders[conditionalOrderId] = ConditionalOrder({
            marketKey: _marketKey,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            targetPrice: _targetPrice,
            gelatoTaskId: taskId,
            conditionalOrderType: _conditionalOrderType,
            desiredFillPrice: _desiredFillPrice,
            reduceOnly: _reduceOnly
        });

        EVENTS.emitConditionalOrderPlaced({
            conditionalOrderId: conditionalOrderId,
            gelatoTaskId: taskId,
            marketKey: _marketKey,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            targetPrice: _targetPrice,
            conditionalOrderType: _conditionalOrderType,
            desiredFillPrice: _desiredFillPrice,
            reduceOnly: _reduceOnly
        });

        ++conditionalOrderId;
    }

    function _sufficientMargin(int256 _marginOut) internal view {
        if (_abs(_marginOut) > freeMargin()) {
            revert InsufficientFreeMargin(freeMargin(), _abs(_marginOut));
        }
    }

    function minMargin(address market) external returns (uint) {
        return IPerpsV2MarketConsolidated(market).minInitialMargin();
    }

    function getprice(address market) external view returns (uint256, bool) {
        return IPerpsV2MarketConsolidated(market).assetPrice();
    }

    function perpsV2SubmitDelayedOrder(
        address _market,
        int256 _sizeDelta,
        uint256 _desiredFillPrice
    ) public {
        IPerpsV2MarketConsolidated(_market)
            .submitOffchainDelayedOrderWithTracking({
                sizeDelta: _sizeDelta,
                desiredFillPrice: _desiredFillPrice,
                trackingCode: TRACKING_CODE
            });
    }

    function _createGelatoTask() internal returns (bytes32 taskId) {
        IOps.ModuleData memory moduleData = _createGelatoModuleData();
        

        taskId = IOps(OPS).createTask({
            execAddress: address(this),
            execData: abi.encodeCall(
                this.executeConditionalOrder,
                conditionalOrderId
            ),
            moduleData: moduleData,
            feeToken: ETH
        });
    }

    function perpsV2WithdrawAllMargin(address _market) external {
        IPerpsV2MarketConsolidated(_market).withdrawAllMargin();
    }

    function _perpsV2ClosePosition(
        address _market,
        uint256 _desiredFillPrice
    ) external {
        // close position (i.e. reduce size to zero)
        /// @dev this does not remove margin from market
        IPerpsV2MarketConsolidated(_market).closePositionWithTracking({
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    function excuteOrder(
        address _market,
        bytes[] calldata priceUpdateData
    ) external payable {
        (bool success, ) = _market.call{value: msg.value}(
            abi.encodeWithSignature(
                "executeOffchainDelayedOrder(address,bytes[])",
                address(this),
                priceUpdateData
            )
        );
        require(success, "executeOffchainDelayedOrder call failed");
    }

    function getPerpsV2Market(
        bytes32 _marketKey
    ) public view returns (IPerpsV2MarketConsolidated market) {
        market = IPerpsV2MarketConsolidated(
            FUTURES_MARKET_MANAGER.marketForKey(_marketKey)
        );

        // sanity check
        assert(address(market) != address(0));
    }

    function getPosition(
        bytes32 _marketKey
    )
        public
        view
        returns (IPerpsV2MarketConsolidated.Position memory position)
    {
        // fetch position data from Synthetix
        position = getPerpsV2Market(_marketKey).positions(address(this));
    }

    function _abs(int256 x) internal pure returns (uint256 z) {
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    function _isSameSign(int256 x, int256 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }

    function _createGelatoModuleData()
        internal
        view
        returns (IOps.ModuleData memory moduleData)
    {
        moduleData = IOps.ModuleData({
            modules: new IOps.Module[](1),
            args: new bytes[](1)
        });

        moduleData.modules[0] = IOps.Module.RESOLVER;
        moduleData.args[0] = abi.encode(
            address(this),
            abi.encodeCall(this.checker, conditionalOrderId)
        );
    }

    function executeConditionalOrder(
        uint256 _conditionalOrderId
    ) external override {
        // verify conditional order is ready for execution
        /// @dev it is understood this is a duplicate check if the executor is Gelato
        if (!_validConditionalOrder(_conditionalOrderId)) {
            revert CannotExecuteConditionalOrder({
                conditionalOrderId: _conditionalOrderId,
                executor: msg.sender
            });
        }

        // store conditional order object in memory
        ConditionalOrder memory conditionalOrder = getConditionalOrder(
            _conditionalOrderId
        );

        // remove conditional order from internal accounting
        delete conditionalOrders[_conditionalOrderId];

        // remove gelato task from their accounting
        /// @dev will revert if task id does not exist {Automate.cancelTask: Task not found}
        /// @dev if executor is not Gelato, the task will still be cancelled
        IOps(OPS).cancelTask({taskId: conditionalOrder.gelatoTaskId});

        // impose and record fee paid to executor
        uint256 fee = _payExecutorFee();

        // define Synthetix PerpsV2 market
        IPerpsV2MarketConsolidated market = getPerpsV2Market(
            conditionalOrder.marketKey
        );

        /// @dev conditional order is valid given checker() returns true; define fill price
        (uint256 fillPrice, PriceOracleUsed priceOracle) = _sUSDRate(market);

        // if conditional order is reduce only, ensure position size is only reduced
        if (conditionalOrder.reduceOnly) {
            int256 currentSize = market
                .positions({account: address(this)})
                .size;

            // ensure position exists and incoming size delta is NOT the same sign
            /// @dev if incoming size delta is the same sign, then the conditional order is not reduce only
            if (
                currentSize == 0 ||
                _isSameSign(currentSize, conditionalOrder.sizeDelta)
            ) {
                EVENTS.emitConditionalOrderCancelled({
                    conditionalOrderId: _conditionalOrderId,
                    gelatoTaskId: conditionalOrder.gelatoTaskId,
                    reason: ConditionalOrderCancelledReason
                        .CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY
                });

                return;
            }

            // ensure incoming size delta is not larger than current position size
            /// @dev reduce only conditional orders can only reduce position size (i.e. approach size of zero) and
            /// cannot cross that boundary (i.e. short -> long or long -> short)
            if (_abs(conditionalOrder.sizeDelta) > _abs(currentSize)) {
                // bound conditional order size delta to current position size
                conditionalOrder.sizeDelta = -currentSize;
            }
        }

        // if margin was committed, free it
        if (conditionalOrder.marginDelta > 0) {
            committedMargin -= _abs(conditionalOrder.marginDelta);
        }

        // execute trade
        perpsV2ModifyMargin({
            _market: address(market),
            _amount: conditionalOrder.marginDelta
        });

        perpsV2SubmitDelayedOrder({
            _market: address(market),
            _sizeDelta: conditionalOrder.sizeDelta,
            _desiredFillPrice: conditionalOrder.desiredFillPrice
        });

        EVENTS.emitConditionalOrderFilled({
            conditionalOrderId: _conditionalOrderId,
            gelatoTaskId: conditionalOrder.gelatoTaskId,
            fillPrice: fillPrice,
            keeperFee: fee,
            priceOracle: priceOracle
        });
    }

    function _sUSDRate(
        IPerpsV2MarketConsolidated _market
    ) internal view returns (uint256, PriceOracleUsed) {
        /// @dev will revert if market is invalid
        bytes32 assetId = _market.baseAsset();

        /// @dev can revert if assetId is invalid OR there's no price for the given asset
        (uint256 price, uint256 publishTime) = PERPS_V2_EXCHANGE_RATE
            .resolveAndGetLatestPrice(assetId);

        // resolveAndGetLatestPrice is provide by pyth
        PriceOracleUsed priceOracle = PriceOracleUsed.PYTH;

        // if the price is stale, get the latest price from the market
        // (i.e. Chainlink provided price)
        if (publishTime < block.timestamp - MAX_PRICE_LATENCY) {
            // set price oracle used to Chainlink
            priceOracle = PriceOracleUsed.CHAINLINK;

            // fetch asset price and ensure it is valid
            bool invalid;
            (price, invalid) = _market.assetPrice();
            if (invalid) revert InvalidPrice();
        }

        /// @dev see IPerpsV2ExchangeRates to understand risks associated with this price
        return (price, priceOracle);
    }

    function _payExecutorFee() internal returns (uint256 fee) {
        if (msg.sender == OPS) {
            (fee, ) = IOps(OPS).getFeeDetails();
            _transfer({_amount: fee});
        } else {
            fee = executorFee;
            (bool success, ) = msg.sender.call{value: fee}("");
            if (!success) revert CannotPayExecutorFee(fee, msg.sender);
        }
    }

    /// @inheritdoc IAccount
    function getConditionalOrder(
        uint256 _conditionalOrderId
    ) public view override returns (ConditionalOrder memory) {
        return conditionalOrders[_conditionalOrderId];
    }

    function checker(
        uint256 _conditionalOrderId
    ) external view returns (bool canExec, bytes memory execPayload) {
        canExec = _validConditionalOrder(_conditionalOrderId);

        // calldata for execute func
        execPayload = abi.encodeCall(
            this.executeConditionalOrder,
            _conditionalOrderId
        );
    }

    function _validConditionalOrder(
        uint256 _conditionalOrderId
    ) internal view returns (bool) {
        ConditionalOrder memory conditionalOrder = getConditionalOrder(
            _conditionalOrderId
        );

        // return false if market key is the default value (i.e. "")
        if (conditionalOrder.marketKey == bytes32(0)) {
            return false;
        }

        // return false if market is paused
        try
            SYSTEM_STATUS.requireFuturesMarketActive(conditionalOrder.marketKey)
        {} catch {
            return false;
        }

        /// @dev if marketKey is invalid, this will revert
        (uint256 price, ) = _sUSDRate(
            getPerpsV2Market(conditionalOrder.marketKey)
        );

        // check if markets satisfy specific order type
        if (
            conditionalOrder.conditionalOrderType == ConditionalOrderTypes.LIMIT
        ) {
            return _validLimitOrder(conditionalOrder, price);
        } else if (
            conditionalOrder.conditionalOrderType == ConditionalOrderTypes.STOP
        ) {
            return _validStopOrder(conditionalOrder, price);
        }

        // unknown order type
        return false;
    }

    function _validLimitOrder(
        ConditionalOrder memory _conditionalOrder,
        uint256 _price
    ) internal pure returns (bool) {
        if (_conditionalOrder.sizeDelta > 0) {
            // Long: increase position size (buy) once *below* target price
            // ex: open long position once price is below target
            return _price <= _conditionalOrder.targetPrice;
        } else {
            // Short: decrease position size (sell) once *above* target price
            // ex: open short position once price is above target
            return _price >= _conditionalOrder.targetPrice;
        }
    }

    function _validStopOrder(
        ConditionalOrder memory _conditionalOrder,
        uint256 _price
    ) internal pure returns (bool) {
        if (_conditionalOrder.sizeDelta > 0) {
            // Long: increase position size (buy) once *above* target price
            // ex: unwind short position once price is above target (prevent further loss)
            return _price >= _conditionalOrder.targetPrice;
        } else {
            // Short: decrease position size (sell) once *below* target price
            // ex: unwind long position once price is below target (prevent further loss)
            return _price <= _conditionalOrder.targetPrice;
        }
    }
}
