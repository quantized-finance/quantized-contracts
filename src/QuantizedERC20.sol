// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./libs/SafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IQuantized.sol";
import "./interfaces/IQuantizedERC20.sol";

import "hardhat/console.sol";

contract QuantizedERC20 is IQuantizedERC20 {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public override allowance;

    address private factory;
    IQuantized private quantized;
    IERC20 private erc20token;

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _quantized, address _erc20token) external override {
        require(msg.sender == factory, "Quantized: FORBIDDEN"); // sufficient check
        quantized = IQuantized(_quantized);
        erc20token = IERC20(_erc20token);
    }

    function _msgSender() internal view returns (address sender) {
        (sender) = msg.sender;
    }

    function name() external view override returns (string memory nam) {
        nam = erc20token.name();
    }

    function symbol() external view override returns (string memory sym) {
        sym = erc20token.symbol();
    }

    function decimals() external view override returns (uint8 dec) {
        dec = erc20token.decimals();
    }

    function totalSupply() external view override returns (uint256 supply) {
        (supply) = erc20token.totalSupply();
    }

    function quantizedSupply() external view override returns (uint256 supply) {
        (supply) = quantized.totalSupply(address(erc20token));
    }

    function balanceOf(address owner) external view override returns (uint256 bal) {
        (bal) = quantized.balanceOf(owner, uint256(address(erc20token)));
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        quantized.setApprovalForAll(spender, true);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        quantized.safeTransferFrom(from, to, uint256(address(erc20token)), value, "0x0");
        emit Transfer(from, to, value);
    }
}
