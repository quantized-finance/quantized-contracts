pragma solidity >=0.5.0;

interface IQuantizedCallee {
    function quantizedCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
