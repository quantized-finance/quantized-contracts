// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../tokens/QuantizedERC20.sol";

contract QuantizedERC20Factory {
    mapping(address => address) private _getQuantized;
    mapping(address => address) private _getQuantizedSource;
    address[] private allQuantized;

    /**
     * @dev emitted when a new quantized token has been added to the system
     */
    event QuantizedCreated(address indexed token, address indexed qtoken, uint256 newLen);

    /**
     * @dev Contract initializer.
     */
    constructor() {
        //
    }

    /**
     * @dev is this a quantized token
     */
    function getQuantizedSource(address _addr) public view returns (address quantizedSource) {
        quantizedSource = _getQuantizedSource[_addr];
    }

    /**
     * @dev get the quantized token for this
     */
    function getQuantized(address _addr) public view returns (address quantizedToken) {
        quantizedToken = _getQuantized[_addr];
    }

    /**
     * @dev number of quantized addresses
     */
    function allQuantizedLength() public view returns (uint256) {
        return allQuantized.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createQuantized(
        address owner,
        address multiToken,
        uint256 tokenHash
    ) public returns (address quantizedToken) {
        require(_getQuantizedSource[address(tokenHash)] == address(0), "TOKEN_EXISTS"); // single check is sufficient
        require(_getQuantized[address(tokenHash)] == address(0), "TOKEN_EXISTS"); // single check is sufficient

        bytes32 salt = keccak256(abi.encodePacked(owner, tokenHash));
        bytes memory bytecode = type(QuantizedERC20).creationCode;
        assembly {
            quantizedToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        QuantizedERC20(quantizedToken).initialize(owner, multiToken);
        _getQuantized[address(tokenHash)] = quantizedToken;
        _getQuantizedSource[quantizedToken] = address(tokenHash);
        allQuantized.push(quantizedToken);
        emit QuantizedCreated(address(tokenHash), quantizedToken, allQuantized.length);
    }
}
