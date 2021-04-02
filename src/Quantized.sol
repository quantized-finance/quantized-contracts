// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./access/Ownable.sol";
import "./libs/SafeMath.sol";
import "./interfaces/IQuantized.sol";
import "./utils/FeeTracker.sol";
import "./factories/QuantizedERC20Factory.sol";
import "./tokens/QuantizedMultiToken.sol";
import "./libs/QuantizedLib.sol";

contract Quantized is Ownable, IQuantized {
    using SafeMath for uint256;

    address private multitoken;
    address private erc20factory;
    address private feesTracker;

    function inithash() public returns (bytes32) {}

    function initialize(
        address _multitoken,
        address _erc20factory,
        address _feesTracker
    ) public payable {
        // initializer always passes three valid addresses so checking just one address is sufficient
        require(multitoken == address(0), "IMMUTABLE");
        multitoken = _multitoken;
        erc20factory = _erc20factory;
        feesTracker = _feesTracker;
    }

    /**
     * @dev Quantize this token (turn it into a mapped Quantized token type as well as a CREATE2-deployed ERC20 contract mapped to the token type.)
     */
    function quantize(
        address token,
        uint256 amount,
        bool exactDebit
    ) external override {
        require(amount > 0, "ZERO_AMOUNT"); // cannot quantize zero tokens
        require(token != address(0x0), "ZERO_ADDRESS"); // cannot quantize the sero address
        require(QuantizedERC20Factory(erc20factory).getQuantizedSource(token) == address(0), "ALREADY_QUANTIZED");

        // get the balances and fees we are gonna need
        (uint256 tbal, , , , uint256 qfee, uint256 ttotal) =
            QuantizedLib.getFeesAndBalances(
                address(this),
                msg.sender,
                token,
                FeeTracker(feesTracker).feeDivisor(token),
                amount
            );

        // revert if the sender token balance is insufficient
        require(tbal >= (exactDebit ? amount : ttotal), "INSUFFICIENT_TOKEN");

        // look for the quantized token contract and create it if not there.
        // reward user for having to pay for this tx
        address quantizedToken = QuantizedERC20Factory(erc20factory).getQuantized(token);
        if (quantizedToken == address(0)) {
            // revert if there is no Uniswap pool for this token
            require(QuantizedLib.uniswapPoolExists(token) == true, "NO_UNISWAP_POOL");

            // create the new quantized token contract
            quantizedToken = QuantizedERC20Factory(erc20factory).createQuantized(
                address(this),
                multitoken,
                uint256(token)
            );

            // mint fee tokens that will pay for dequantizing later
            QuantizedMultiToken(multitoken).mint(msg.sender, address(0), qfee.mul(50));
        }

        // mint fee tokens that will pay for dequantizing later
        QuantizedMultiToken(multitoken).mint(msg.sender, address(0), qfee.mul(qfee));

        // transfer erc20 tokens to quantizer contract
        IERC20(token).transferFrom(msg.sender, address(this), (exactDebit ? tbal : ttotal));

        // mint equivalent number of quantized tokens
        QuantizedMultiToken(multitoken).mint(msg.sender, token, exactDebit ? amount - tbal : amount);

        // emit an event about it
        emit TokenQuantized(msg.sender, token, quantizedToken, exactDebit ? amount - tbal : amount, qfee);
    }

    /**
     * @dev Quantize ETH (turn it into quanta)
     */
    receive() external payable {
        // tranfer ETH to contract and mint QUanta
        uint256 quantaToMint = msg.sender.balance.mul(QuantizedLib.QUANTA_ETH_MULTIPLIER);
        QuantizedMultiToken(multitoken).mint(msg.sender, address(0), quantaToMint);
        emit EthereumQuantized(msg.sender, msg.sender.balance, quantaToMint);
    }

    /**
     * @dev Dequantize this token to erc20.
     */
    function dequantize(address token, uint256 amount) external override {
        // cannot dequantize a quantized token so stop them right here
        require(QuantizedERC20Factory(erc20factory).getQuantizedSource(token) == address(0), "ALEADY_QUANTIZED");

        // get the address of the quantized token
        address quantizedToken = QuantizedERC20Factory(erc20factory).getQuantized(token);

        // cannot dequantize token that is not quantized
        require(quantizedToken != address(0), "NOT_QUANTIZED");

        // balance and fee info for token
        (, uint256 qbal, uint256 zbal, , uint256 qfee, ) =
            QuantizedLib.getFeesAndBalances(
                address(this),
                msg.sender,
                token,
                FeeTracker(feesTracker).feeDivisor(token),
                amount
            );

        // require they have enough of this quantized token to dequantize
        require(zbal >= amount, "Insufficient quantized token balance");
        // require them not to need any additional quanta to satistfy the fee
        require(qbal >= qfee, "Insufficient quanta balance to dequantize token.");

        // burn the quantized tokens that are being dequantized
        QuantizedMultiToken(multitoken).burn(msg.sender, token, amount);

        // burn the Quanta fees paid to dequantize the token
        QuantizedMultiToken(multitoken).burn(msg.sender, address(0), qfee);

        // transfer erc20 token balance to dequantizer address
        IERC20(token).transferFrom(address(this), msg.sender, amount);

        // emit an event about it
        emit TokenDequantized(msg.sender, token, quantizedToken, amount, qfee);
    }
}
