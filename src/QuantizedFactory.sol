pragma solidity >=0.7.0;

import "./interfaces/IQuantizedFactory.sol";
import "./QuantizedERC20.sol";

import "hardhat/console.sol";

contract QuantizedFactory is IQuantizedFactory {
    address private quantized;
    mapping(address => address) public override getQuantized;
    address[] public override allQuantized;

    function inithash() public returns (bytes32) {}

    constructor(address _quantized) {
        quantized = _quantized;
    }

    function allQuantizedLength() external view override returns (uint256) {
        return allQuantized.length;
    }

    function createQuantized(address tokenA) external override returns (address quantizedToken) {
        require(quantized == msg.sender, "Quantized: NOT_QUANTIZED"); // single check is sufficient
        require(getQuantized[tokenA] == address(0), "Quantized: TOKEN_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(QuantizedERC20).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA));
        assembly {
            quantizedToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        console.logArray(keccak256(bytecode)[12:]);
        IQuantizedERC20(quantizedToken).initialize(quantized, tokenA);
        getQuantized[tokenA] = quantizedToken;
        allQuantized.push(quantizedToken);
        emit QuantizedCreated(tokenA, quantizedToken, allQuantized.length);
    }
}
