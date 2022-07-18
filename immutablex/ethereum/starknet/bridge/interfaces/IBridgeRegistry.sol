// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

/**
 * @title A registry where Token Contract owners can register their custom Starknet bridge for discovery
 * @dev Implementers of this interface can be used to discover bridges for presentation to end users
 */
interface IBridgeRegistry {
    /**
     * @dev a struct to hold an L1 Ethereum bridge address and an L2 Starknet bridge address
     */
    struct BridgePair {
        address l1BridgeAddress;
        uint256 l2BridgeAddress;
    }

    /**
     * @dev event emitted when a token contract owner invokes setCustomTokenBridge
     */
    event RegisterToken(
        address indexed _from,
        address indexed _l1TokenAddress,
        uint256 indexed _l2TokenAddress
    );

    /**
     * @dev get the standard token bridge
     */
    function getStandardTokenBridge() external view returns (BridgePair memory);

    /**
     * @dev get the l2 token address for a given l2 token
     */
    function getL2Token(address l1TokenAddress) external view returns (uint256);

    /**
     * @dev set the l2 token address for a token. Can only be set by owner.
     */
    function registerToken(address l1TokenAddress, uint256 l2TokenAddress)
        external;
}
