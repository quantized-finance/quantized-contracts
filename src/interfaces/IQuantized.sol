// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IQuantized {
    event EthereumQuantized(address indexed account, uint256 amount, uint256 minted);
    event TokenQuantized(
        address indexed account,
        address indexed token,
        address indexed quantizedToken,
        uint256 amount,
        uint256 qfee
    );
    event TokenDequantized(
        address indexed account,
        address indexed token,
        address indexed quantizedToken,
        uint256 amount,
        uint256 qfee
    );

    function quantize(
        address token,
        uint256 amount,
        bool exactDebit
    ) external;

    function dequantize(address token, uint256 amount) external;
}
