// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../tokens/QuantizedERC20.sol";

import "hardhat/console.sol";

contract QuantizedERC20Factory {
    address private operator;

    mapping(address => address) private _getQuantized;
    mapping(address => address) private _getQuantizedSource;
    address[] private _allQuantized;

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
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
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
     * @dev get the quantized token for this
     */
    function allQuantized(uint256 idx) public view returns (address quantizedToken) {
        quantizedToken = _allQuantized[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allQuantizedLength() public view returns (uint256) {
        return _allQuantized.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createQuantized(
        address owner,
        address multiToken,
        uint256 tokenHash
    ) public returns (address quantizedToken) {
        require(msg.sender == operator, "UNAUTHORIZED"); // only the operator may create new ERC20 tokens
        require(_getQuantizedSource[address(tokenHash)] == address(0), "TOKEN_EXISTS"); // single check is sufficient
        require(_getQuantized[address(tokenHash)] == address(0), "TOKEN_EXISTS"); // single check is sufficient

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes32 salt = keccak256(abi.encodePacked(owner, multiToken, tokenHash));
        bytes memory bytecode = type(QuantizedERC20).creationCode;
        assembly {
            quantizedToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // initialize the erc20 contract with the relevant addresses which it proxies
        QuantizedERC20(quantizedToken).initialize(owner, multiToken, address(tokenHash));

        console.log("createQuantized", tokenHash, quantizedToken);

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getQuantized[address(tokenHash)] = quantizedToken;
        _getQuantizedSource[quantizedToken] = address(tokenHash);
        _allQuantized.push(quantizedToken);
        emit QuantizedCreated(address(tokenHash), quantizedToken, _allQuantized.length);
    }
}
