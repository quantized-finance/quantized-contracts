// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libs/Strings.sol";
import "./libs/QuantizedLib.sol";

import "./interfaces/IQuantized.sol";
import "./interfaces/IQuantizedFactory.sol";

contract Quantized is ERC1155, ERC1155Holder, Pausable, Ownable, IQuantized {
    using Strings for string;

    address private _factory;
    address private _quanta;
    address private _governance;

    mapping(uint256 => uint256) private totalSupplies;
    mapping(address => uint256) private feeDivisors;

    /**
     * @dev Modifier to make a function callable only when the caller is owner or sender
     *
     * Requirements:
     *
     * - The caller is owner or sender of this token.
     */
    modifier ownerSenderOnly(address account) {
        require(_isOwner(account) || _isSender(account), "Quantized: caller is not owner nor sender");
        _;
    }

    /**
     * @dev Contract initializer.
     */
    constructor() ERC1155("https://metadata.quantizer.finance/metadata/") {
        setApprovalForAll(address(this), true);
    }

    /**
     * @dev Returns true if message sender is the given account
     */
    function _isSender(address account) internal view returns (bool) {
        return _msgSender() == account;
    }

    /**
     * @dev Returns true if account is owner
     */
    function _isOwner(address account) internal view returns (bool) {
        return owner() == account;
    }

    /**
     * @dev Get the total existing supply of quantized tokens for this erc20
     */
    function totalSupply(address _addr) external view override returns (uint256) {
        return totalSupplies[uint256(_addr)];
    }

    /**
     * @dev Get the total balance of held for this erc20
     */
    function totalBalanceOf(address _addr) public view returns (uint256) {
        return ERC20(_addr).balanceOf(address(this));
    }

    function feeDivisor(address token) public view returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? QuantizedLib.QUANTA_ETH_MULTIPLIER : divisor;
    }

    function setFeeDivisor(address token, uint256 _feeDivisor) public onlyOwner returns (uint256 oldDivisor) {
        require(_feeDivisor != 0, "fee divisor cannot be 0");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
    }

    function setFactory(address f) public {
        require(_factory == address(0x0), "Factory is immutable");
        _factory = f;
        _quanta = IQuantizedFactory(_factory).createQuantized(address(0x0));
        _governance = IQuantizedFactory(_factory).createQuantized(address(0x1));
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function quanta() public view returns (address) {
        return _quanta;
    }

    function goverenance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Quantize this token (turn it into a mapped Quantized token type as well as a CREATE2-deployed ERC20 contract mapped to the token type.)
     */
    function quantize(address token, uint256 amount) external {
        (uint256 tbal, , , , uint256 qfee, uint256 atotal) =
            QuantizedLib.getFeesAndBalances(address(this), _msgSender(), token, feeDivisor(token), amount);
        require(tbal >= atotal, "Insufficient token balance");
        // look for the quantized token contract and create it if not there.
        // reward user for having to pay for this tx
        if (IQuantizedFactory(_factory).getQuantized(token) == address(0x0)) {
            address quantizedToken = IQuantizedFactory(_factory).createQuantized(token);
            // calculate a reward for this activity
            uint256 qreward = qfee * 50;
            // mint fee tokens that will pay for dequantizing later
            _mint(_msgSender(), 0, qreward, "0x0");
            emit QuantizedTokenGenerated(_msgSender(), quantizedToken, amount, qreward);
        }
        // mint fee tokens that will pay for dequantizing later
        _mint(_msgSender(), 0, qfee, "0x0");
        // transfer erc20 tokens to quantizer contract
        IERC20(token).transferFrom(_msgSender(), address(this), atotal);
        // mint equivalent number of quantized tokens
        _mint(_msgSender(), uint256(token), amount, "0x0");
        // emit an event about it
        emit Quantized(_msgSender(), token, amount, atotal - amount);
    }

    /**
     * @dev Quantize ETH (turn it into quanta)
     */
    function quantizeEth(uint256 amount) external payable {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        // tranfer ETH to contract and mint QUanta
        address(this).transfer(amount);
        _mint(_msgSender(), 0, amount * QuantizedLib.QUANTA_ETH_MULTIPLIER, "0x0");
        emit QuantizedEth(_msgSender(), amount, amount * QuantizedLib.QUANTA_ETH_MULTIPLIER);
    }

    /**
     * @dev Dequantize this token to erc20.
     */
    function dequantize(address token, uint256 amount) external {
        (, uint256 qbal, uint256 zbal, , uint256 qfee, ) =
            QuantizedLib.getFeesAndBalances(address(this), _msgSender(), token, feeDivisor(token), amount);
        // require they have enough of this quantized token to dequantize
        require(zbal >= amount, "Insufficient quantized token balance");
        // require them not to need any additional quanta to satistfy the fee
        require(qbal >= qfee, "Insufficient quanta balance to dequantize token.");
        // burn the quantized tokens that are being dequantized
        _burn(_msgSender(), uint256(token), amount);
        // burn the Quanta fees
        _burn(_msgSender(), 0, qfee);
        // transfer erc20 token balance to dequantizer address
        IERC20(token).transferFrom(address(this), _msgSender(), amount);
        // emit an event about it
        emit Dequantized(_msgSender(), token, amount, qfee);
    }

    /**
     * @dev Dequantize this token to erc20, using ETH to pay for fees
     */
    function dequantizeEth(address token, uint256 amount) external payable {
        (, , uint256 zbal, , uint256 qfee, ) =
            QuantizedLib.getFeesAndBalances(address(this), _msgSender(), token, feeDivisor(token), amount);
        address dequantizer = _msgSender();
        // require they have enough erc1155 token to mint this erc1155
        require(zbal >= amount, "Insufficient quantized token balance");
        // get a price quote in ETH of the cost of the Quanta we need to pay fees with
        (uint256 qneth, , ) = QuantizedLib.ethQuote(_quanta, qfee);
        // require they have enough ETH needed to pay their fees
        require(dequantizer.balance > qneth, "Insufficient eth balance to dequantize token.");
        // convert eth into quanta via uniswap to get the quanta needed to pay fees
        convertEthToQuanta(qfee);
        // pay quanta fees by burning quanta token
        _burn(dequantizer, 0, qfee);
        // burn the quantized tokenss we are dequantizing
        _burn(dequantizer, uint256(token), amount);
        // transfer erc20 back to dequantizer address
        IERC20(token).transferFrom(address(this), dequantizer, amount);
        // emit an event about it
        emit Dequantized(_msgSender(), token, amount, qneth);
    }

    function convertEthToQuanta(uint256 quantaAmount) public payable {
        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        QuantizedLib.convertEthToQuanta(_factory, address(this), quantaAmount, deadline);
    }

    /**
     * @dev Returns the metadata URI for this token type
     */
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        require(this.totalSupply(address(_id)) != 0, "QuantizedERC20#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(ERC1155(this).uri(_id), Strings.uint2str(_id));
    }

    /**
     * @dev run every time a token is tranferred
     */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override(ERC1155) {
        for (uint256 idx = 0; idx < ids.length; idx++) {
            uint256 id_x = ids[idx];
            uint256 amount_x = amounts[idx];
            if (from == address(0x0)) {
                // inc total supplies for this token type
                totalSupplies[id_x] = totalSupplies[id_x] + (amount_x);
            } else if (to == address(0x0)) {
                if (totalSupplies[id_x] > amount_x) {
                    totalSupplies[id_x] = totalSupplies[id_x] - (amount_x);
                }
            }
        }
    }
}
