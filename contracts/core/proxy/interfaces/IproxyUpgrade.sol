// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC1967.sol";
/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and its upgradeability mechanism is implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
       function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) external  payable ;
}