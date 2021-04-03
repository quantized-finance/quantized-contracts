// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library GovernanceLib {
    // calculates the CREATE2 address for the quantized erc20 without making any external calls
    function governanceAddressOfPropoal(
        address qfactory,
        address _creator,
        uint256 _proposalId,
        uint8 _proposalType,
        address _token,
        uint256 _newValue
    ) public pure returns (address govAddress) {
        govAddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        qfactory,
                        keccak256(abi.encodePacked(qfactory, _creator, _proposalId, _proposalType, _token, _newValue)),
                        hex"562fe3b22be461a7814edb71662612a8844cf0436428c2c708abbb67beb2ec7b" // init code hash
                    )
                )
            )
        );
    }
}
