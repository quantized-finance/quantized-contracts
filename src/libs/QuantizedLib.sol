// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library QuantizedLib {
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public constant QUANTA_ETH_MULTIPLIER = 1000000;

    function getFeesAndBalances(
        address quantized,
        address sender,
        address token,
        uint256 feeDivisor,
        uint256 amount
    )
        internal
        view
        returns (
            uint256 tbal,
            uint256 qbal,
            uint256 zbal,
            uint256 tfee,
            uint256 qfee,
            uint256 atotal
        )
    {
        tbal = IERC20(token).balanceOf(sender);
        qbal = IERC1155(quantized).balanceOf(sender, 0);
        zbal = IERC1155(quantized).balanceOf(sender, uint256(token));
        tfee = amount / feeDivisor;
        qfee = toQuanta(token, tfee);
        atotal = amount + tfee;
    }

    function toQuanta(address token, uint256 amount) public view returns (uint256 quanta) {
        (quanta, , ) = ethQuote(token, amount);
        quanta = quanta * QUANTA_ETH_MULTIPLIER;
    }

    function quantaFee(
        address token,
        uint256 amount,
        uint256 feeDivisor
    ) public view returns (uint256 aFee) {
        aFee = toQuanta(token, amount / feeDivisor);
    }

    function convertEthToQuanta(
        address factory,
        address dest,
        uint256 quantaAmount,
        uint256 deadline
    ) public {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        uniswapRouter.swapETHForExactTokens{value: msg.value}(
            quantaAmount,
            getPathForETHToToken(quantizedAddressOf(factory, address(0x0))),
            dest,
            deadline
        );
        // refund leftover ETH to user
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "refund failed");
    }

    // calculates the CREATE2 address for the quantized erc20 without making any external calls
    function quantizedAddressOf(address qfactory, address token0) internal pure returns (address qaddress) {
        qaddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        qfactory,
                        keccak256(abi.encodePacked(token0)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    function ethQuote(address token, uint256 tokenAmount)
        public
        view
        returns (
            uint256 quanta,
            uint256 ReserveA,
            uint256 ReserveB
        )
    {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        (ReserveA, ReserveB) = getReserves(UNISWAP_ROUTER_ADDRESS, token, uniswapRouter.WETH());
        (quanta) = quote(tokenAmount, ReserveA, ReserveB);
    }

    function getPathForETHToToken(address token) public pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        return path;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}
