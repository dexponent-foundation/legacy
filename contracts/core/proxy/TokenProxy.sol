// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../base/storage/TokenStorage.sol";
contract TokenProxy is TokenStorage,TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address dexAdmin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, dexAdmin, _data) {}

    function getAdmin() external returns (address) {
        return _proxyAdmin();
    }

    receive() external payable {}
}
