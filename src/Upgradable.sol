//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error CannotUpgrade();

contract Upgradable is Ownable{

    //A contract address to a new upgraded contract if any
    address public upgradeContract;

    event ContractUpgraded(address newContract);

    /**
     * @notice Set the address of the upgradeContract of the contract. only admin can do this
     * @dev The default value of upgradeContract is the 0 address. Use the 0 address at any time
     * to make the contract not upgradable.
     * @param _upgradeAddress address of an upgraded contract
     */

    function setUpgradeContract(address _upgradeAddress)
        public
        onlyOwner
    {
        upgradeContract = _upgradeAddress;
        emit ContractUpgraded(upgradeContract); 
    }

    /**
     * @notice If the upgrade contract is not set to the 0 address emit a TokenUpgrade event.
     * @dev Use this function before upgrading a token
     */

    function _canUpgradeToken()
    internal
    virtual
    {
        if (address(upgradeContract) == address(0)) {
            revert CannotUpgrade();
        }
    }

}
