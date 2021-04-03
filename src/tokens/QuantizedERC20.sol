// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IQuantizedERC20.sol";

contract QuantizedERC20 is IQuantizedERC20, IERC20 {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowance;

    address private quantized;
    address private erc1155token;
    address private erc20token;

    constructor() {}

    // called once by the factory at time of deployment
    function initialize(
        address _quantized,
        address _erc1155token,
        address _erc20token
    ) external override {
        require(address(0) == quantized, "Quantized: FORBIDDEN"); // sufficient check
        quantized = _quantized;
        erc1155token = _erc1155token;
        erc20token = _erc20token;
    }

    function name() external view override returns (string memory nam) {
        nam = IQuantizedERC20(erc20token).name();
    }

    function symbol() external view override returns (string memory sym) {
        sym = IQuantizedERC20(erc20token).symbol();
    }

    function decimals() external view override returns (uint8 dec) {
        dec = IQuantizedERC20(erc20token).decimals();
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function totalSupply() external view override returns (uint256 supply) {
        (supply) = IERC20(erc20token).totalSupply();
    }

    function quantizedSupply() external view override returns (uint256 supply) {
        (supply) = IERC20(erc20token).balanceOf(quantized);
    }

    function balanceOf(address owner) external view override returns (uint256 bal) {
        (bal) = IERC1155(erc1155token).balanceOf(owner, uint256(erc20token));
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        IERC1155(erc1155token).setApprovalForAll(spender, true);
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
        if (_allowance[from][msg.sender] != uint256(-1)) {
            _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function transferMany(
        address from,
        address[] memory to,
        uint256[] memory value
    ) external override returns (bool) {
        require(to.length > 0, "ZERO_DESTINATION");
        require(to.length == value.length, "to and value lengths do not match");
        for (uint256 i = 0; i < to.length; i++) {
            if (_allowance[from][msg.sender] != uint256(-1)) {
                _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value[i]);
            }
            _transfer(from, to[i], value[i]);
        }
        return true;
    }

    function transferBatch(
        address from,
        address to,
        uint256[] memory tokens,
        uint256[] memory amounts
    ) external override {
        require(to != address(0), "ZERO_DESTINATION");
        IERC1155(erc1155token).safeBatchTransferFrom(from, to, tokens, amounts, "0x0");
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        if (_allowance[from][msg.sender] != uint256(-1)) {
            _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        }
        IERC1155(erc1155token).safeTransferFrom(from, to, uint256(erc20token), value, "0x0");
        emit Transfer(from, to, value);
    }
}
