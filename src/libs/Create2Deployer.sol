// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

library Create2Deployer {
    /**
     * @dev deploy a new erc20 token using create2
     */
    function create2bytecode(bytes memory bytecode, bytes32 salt) public returns (address createdContract) {
        assembly {
            createdContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }
}
