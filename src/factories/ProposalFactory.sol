// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/GovernanceLib.sol";
import "../libs/SafeMath.sol";
import "../governance/Proposal.sol";

contract ProposalFactory {
    using SafeMath for uint256;

    address private operator;
    uint256 nextProposalId;

    mapping(address => address) private _getProposal;
    address[] private _allProposed;

    /**
     * @dev emitted when a new proposal token has been added to the system
     */
    event ProposalCreated(address creator, uint256 proposalId, uint8 proposalType, address token, uint256 newValue);

    /**
     * @dev Contract initializer.
     */
    constructor() {
        //
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
    }

    /**
     * @dev get the proposal token for this
     */
    function getProposed(address idx) public view returns (address proposal) {
        proposal = _getProposal[idx];
    }

    /**
     * @dev get the quantized token for this
     */
    function allProposed(uint256 idx) public view returns (address proposal) {
        proposal = _allProposed[idx];
    }

    /**
     * @dev number of proposal addresses
     */
    function allProposedLength() public view returns (uint256) {
        return _allProposed.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createProposal(
        address owner,
        address proposer,
        uint8 proposalType,
        address token,
        uint256 newValue
    ) public returns (uint256 proposalId, address proposalContract) {
        require(msg.sender == operator, "UNAUTHORIZED");
        bytes32 salt = keccak256(abi.encodePacked(owner, proposer, nextProposalId));
        bytes memory bytecode = type(Proposal).creationCode;
        assembly {
            proposalContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Proposal(proposalContract).initialize(proposer, nextProposalId, proposalType, token, newValue);
        _getProposal[proposalContract] = proposalContract;
        proposalId = nextProposalId;
        _allProposed.push(proposalContract);

        nextProposalId = nextProposalId.add(1);

        emit ProposalCreated(proposer, nextProposalId.sub(1), proposalType, token, newValue);
    }
}
