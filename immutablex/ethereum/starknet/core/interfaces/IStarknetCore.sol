// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

import "./IStarknetMessaging.sol";

/**
 * This interface is required as IStarknetMessaging does not expose the external functions in StarknetMessaging
 * We create this interface as we do not wish to modify StarknetMessaging and IStarknetMessaging
 */
interface IStarknetCore is IStarknetMessaging {
    /**
     *returns > 0 if there is a message ready for consumption with the given msgHash
     */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);

    /**
     * returns the current nonce counter of the starknet messaging contract
     * This is actually defined as a public function in implementation
     */
    function l1ToL2MessageNonce() external view returns (uint256);
}
