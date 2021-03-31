// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IQuantized is IERC1155 {
    /**
     * @dev Emitted when an erc20 token is quantized (erc20 tokens tranferred to contract, erc1155 minted and transferred to quantizer)
     */
    event QuantizedTokenGenerated(address indexed quantizer, address indexed token, uint256 amount, uint256 feesPaid);

    /**
     * @dev Emitted when an erc20 token is quantized (erc20 tokens tranferred to contract, erc1155 minted and transferred to quantizer)
     */
    event Quantized(address indexed quantizer, address indexed token, uint256 amount, uint256 feesPaid);

    /**
     * @dev Emitted when an ETH is quantized (turned into Quanta )
     */
    event QuantizedEth(address indexed quantizer, uint256 amount, uint256 quanta);

    /**
     * @dev Emitted when an erc20 token is dequantized (erc1155 burned and erc20 tokens returned) and paid for in QUANTA
     */
    event Dequantized(address indexed dequantizer, address indexed token, uint256 amount, uint256 feesPaid);

    /**
     * @dev Emitted when an erc20 token is dequantized (erc1155 burned and erc20 tokens returned) and paid for in ETH
     */
    event DequantizedETH(address indexed dequantizer, address indexed token, uint256 amount, uint256 feesPaid);

    /**
     * @dev Total supply of quantized token
     */
    function totalSupply(address _addr) external view returns (uint256);
}
