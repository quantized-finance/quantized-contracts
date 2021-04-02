// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/Strings.sol";
import "../libs/SafeMath.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Holder.sol";
import "../access/Ownable.sol";
import "../interfaces/IQuantizedMultiToken.sol";
import "../interfaces/IQuantizedMultiToken.sol";

contract QuantizedMultiToken is ERC1155Pausable, ERC1155Holder, IQuantizedMultiToken, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    mapping(uint256 => uint256) private _totalBalances;

    function inithash() public returns (bytes32) {}

    /**
     * @dev Contract initializer.
     */
    constructor() ERC1155("https://metadata.quantized.finance/quantized/") {}

    /**
     * @dev Returns the metadata URI for this token type
     */
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        require(_totalBalances[_id] != 0, "QuantizedERC1155#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(ERC1155Pausable(this).uri(_id), Strings.uint2str(_id));
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function totalBalances(uint256 _id) public view returns (uint256) {
        return _totalBalances[_id];
    }

    /**
     * @dev mint some amount of tokens. Only callable by token owner
     */
    function mint(
        address account,
        address token,
        uint256 amount
    ) public onlyOwner {
        _mint(account, uint256(token), amount, "0x0");
        _totalBalances[uint256(token)] = _totalBalances[uint256(token)].add(amount);
        emit QuantizedTokenGenerated(account, token, amount);
    }

    /**
     * @dev mint some amount of tokens. Only callable by token owner
     */
    function burn(
        address account,
        address token,
        uint256 amount
    ) public onlyOwner {
        _burn(account, uint256(token), amount);
        _totalBalances[uint256(token)] = _totalBalances[uint256(token)].sub(amount);
    }
}
