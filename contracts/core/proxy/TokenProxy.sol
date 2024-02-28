// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../base/storage/TokenStorage.sol";
contract TokenProxy is TokenStorage,TransparentUpgradeableProxy {
    address proxyAdmin;
    constructor(
        address _logic,
        address dexAdmin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, dexAdmin, _data) {}

    function setAdmin() external {
        proxyAdmin =  _proxyAdmin();
    }
    function getAdmin() external  view returns (address){
        return proxyAdmin;
    }
    receive() external payable {}
}

