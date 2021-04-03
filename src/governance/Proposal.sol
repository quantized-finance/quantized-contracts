// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract Proposal {
    function inithash() public returns (bytes32) {}

    uint256 private proposalId;
    enum ProposalType {
        FEE_DIVISOR_CHANGE,
        CREATE_MULTIPLIER_CHANGE,
        DEFAULT_FEE_DIVISOR_CHANGE,
        DEFAULT_CREATE_MULTIPLIER_CHANGE,
        REPLACE_FEE_TRACKER,
        REPLACE_MULTITOKEN,
        REPLACE_FACTORY
    }

    ProposalType private proposalType;
    address private creator;
    address private token;
    uint256 private newValue;
    uint256 private timestamp;

    function initialize(
        address _creator,
        uint256 _proposalId,
        uint8 _proposalType,
        address _token,
        uint256 _newValue
    ) public {
        require(proposalId == 0, "IMMUTABLE");
        creator = _creator;
        proposalType = ProposalType(_proposalType);
        proposalId = _proposalId;
        token = _token;
        newValue = _newValue;
        timestamp = block.timestamp;
    }

    function data()
        public
        view
        returns (
            uint256,
            address,
            uint8,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        return (proposalId, creator, uint8(proposalType), timestamp, token, newValue, timestamp);
    }
}
