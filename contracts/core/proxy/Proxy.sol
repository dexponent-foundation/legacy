pragma solidity =0.8.20;
import "../base/StakingMasterStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract dexProxy is StakingMasterStorage, TransparentUpgradeableProxy {    address admin;
    address proxyAdmin;
    constructor(
        address _logic,
        address dexAdmin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, dexAdmin, _data) {
    }
    function setAdmin() external {
        proxyAdmin =  _proxyAdmin();
    }
    function getAdmin() external  view returns (address){
        return proxyAdmin;
    }
  receive() external payable {}
  
}