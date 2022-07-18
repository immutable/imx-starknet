// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

import "./CairoConstants.sol";

library StarknetUtilities {
    function isValidL2Address(uint256 l2Address) internal pure returns (bool) {
        return (l2Address != 0) && (l2Address < CairoConstants.FIELD_PRIME);
    }

    function getL1ToL2MsgHash(
        uint256 toAddress,
        uint256 selector,
        uint256[] memory payload,
        address sender,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint256(uint160(address(sender))),
                    toAddress,
                    nonce,
                    selector,
                    payload.length,
                    payload
                )
            );
    }
}
