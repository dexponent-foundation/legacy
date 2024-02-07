// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./StakingMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeHolder {
    address public staker;
    address public masterContract;
    IERC20 public  abrToken;
    bool private approved = false;
    event DepositReceived(address indexed from, uint256 amount);
    event FundsSent(address indexed to, uint256 amount);


    constructor(address _staker, address _masterContract,IERC20 _arb) {
        staker = _staker;
        masterContract = _masterContract;
        abrToken = _arb;
    }

    modifier onlyMasterOwner() {
        require(masterContract == msg.sender, "Caller is not the master owner");
        _;
    }

    receive() external payable {
        revert();
    }

    function withdrawArb(uint256 amount, address account) public onlyMasterOwner {
        require(
            amount > 0,
            "Invalid withdrawal amount"
        );
        require(abrToken.transfer(account,amount),"Tnx failed");
    }

    // Function to get the balance of Cleth tokens
    function getClethBalance() external view returns (uint256) {
        return abrToken.balanceOf(address(this));
    }

}
