// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract TestERC20 is ERC20 {
    /**
     * @dev Initializes the contract
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 amount
    ) ERC20(name, symbol) {
        if (amount != 0) {
            _mint(_msgSender(), amount * 1 ether);
        }
    }

    /**
     * @dev Mint this amount of tokens - public for test token
     */
    function mint(address account, uint256 amount) external returns (uint256) {
        _mint(account, amount);
    }
}
