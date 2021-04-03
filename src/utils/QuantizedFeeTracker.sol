// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract QuantizedFeeTracker {
    address private operator;

    uint256 private constant CREATION_MULTIPLIER = 50;
    uint256 private constant FEE_DIVISOR = 1000;

    uint256 private _defaultCreationMultiplier;
    uint256 private _defaultFeeDivisor;

    mapping(address => uint256) private creationMultipliers;
    mapping(address => uint256) private feeDivisors;

    event DefaultCreationMultiplierChanged(address indexed operator, uint256 oldValue, uint256 value);
    event DefaultFeeDivisorChanged(address indexed operator, uint256 oldValue, uint256 value);

    event CreationMultiplierChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);

    /**
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
    }

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
    function defaultCreationMultiplier() public view returns (uint256 multiplier) {
        return _defaultCreationMultiplier;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) public view returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultFeeDivisor() public view returns (uint256 multiplier) {
        return _defaultFeeDivisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultFeeDivisor(uint256 _feeDivisor) public returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = _defaultFeeDivisor;
        _defaultFeeDivisor = _feeDivisor;
        emit DefaultFeeDivisorChanged(operator, oldDivisor, _defaultFeeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor) public returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        emit FeeDivisorChanged(operator, token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultCreationMultiplier(uint256 _multiplier) public returns (uint256 oldMultiplier) {
        require(operator == msg.sender, "UNAUTHORIZED");
        oldMultiplier = _defaultCreationMultiplier;
        _defaultCreationMultiplier = _multiplier;
        emit DefaultCreationMultiplierChanged(operator, oldMultiplier, _defaultCreationMultiplier);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setCreationMultiplier(address token, uint256 _multiplier) public returns (uint256 oldMultiplier) {
        require(operator == msg.sender, "UNAUTHORIZED");
        oldMultiplier = creationMultipliers[token];
        creationMultipliers[token] = oldMultiplier;
        emit CreationMultiplierChanged(operator, token, oldMultiplier, _multiplier);
    }
}
