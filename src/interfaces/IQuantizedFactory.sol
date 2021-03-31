pragma solidity >=0.5.0;

interface IQuantizedFactory {
    event QuantizedCreated(address indexed token0, address quantized, uint256);

    function getQuantized(address tokenA) external view returns (address quantized);

    function allQuantized(uint256) external view returns (address quantized);

    function allQuantizedLength() external view returns (uint256);

    function createQuantized(address tokenA) external returns (address quantized);
}
