// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IQuantizedERC20 {
    // Quantized-specific events and functions

    event QuantizedApproval(address indexed owner, address indexed spender, uint256 value);

    event QuantizedTransfer(address indexed from, address indexed to, uint256 value);

    event QuantizedTransferMany(address indexed from, address[] to, uint256[] values);

    event QuantizedTransferBatch(address indexed from, address indexed to, address[] tokens, uint256[] values);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // enhancement 1 = transfer one token to multiple destinations
    function transferMany(
        address from,
        address[] memory to,
        uint256[] memory amounts
    ) external returns (bool);

    // enhancement 2 - transfer multiple tokens to a single destination
    function transferBatch(
        address from,
        address to,
        uint256[] memory tokens,
        uint256[] memory amounts
    ) external;

    // total supply of quantized tokens
    function quantizedSupply() external view returns (uint256);

    function initialize(address, address) external;
}
