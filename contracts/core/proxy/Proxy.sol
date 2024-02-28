pragma solidity =0.8.20;
import "../base/StakingMasterStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract dexProxy is StakingMasterStorage, TransparentUpgradeableProxy {    address admin;
    
    constructor(
        address _logic,
        address dexAdmin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, dexAdmin, _data) {

    }
    function getAdmin() external returns(address){
        return _proxyAdmin();
    }
receive() external payable {}
  
}