// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../access/Ownable.sol";

contract FeeTracker is Ownable {
    uint256 private constant CREATION_MULTIPLIER = 50;
    uint256 private constant FEE_DIVISOR = 1000;

    mapping(address => uint256) private creationMultipliers;
    mapping(address => uint256) private feeDivisors;

    event CreationMultiplierChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);

    /**
     * @dev construct
     */
    constructor() {}

    /**
     * @dev Get the fee divisor for the specified token
     */
    function creationMultiplier(address token) public view returns (uint256 multiplier) {
        multiplier = creationMultipliers[token];
        multiplier = multiplier == 0 ? CREATION_MULTIPLIER : multiplier;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) public view returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor) public returns (uint256 oldDivisor) {
        require(owner() == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        FeeDivisorChanged(owner(), token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setCreationMultiplier(address token, uint256 _multiplier) public returns (uint256 oldMultiplier) {
        require(owner() == msg.sender, "UNAUTHORIZED");
        oldMultiplier = creationMultipliers[token];
        creationMultipliers[token] = oldMultiplier;
        CreationMultiplierChanged(owner(), token, oldMultiplier, _multiplier);
    }
}
