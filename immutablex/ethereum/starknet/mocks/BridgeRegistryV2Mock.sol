// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "immutablex/ethereum/starknet/core/libraries/StarknetUtilities.sol";
import "../bridge/interfaces/IBridgeRegistry.sol";

contract BridgeRegistryV2Mock is
    Initializable,
    IBridgeRegistry,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    /**
     * @dev mapping from L1 Token Address to L2 Token Address
     */
    mapping(address => uint256) private tokenMappings;

    /**
     * @dev details of the standard ERC721 Bridge
     */
    BridgePair private standardBridge;

    uint256 private newVariable;

    function initialize(BridgePair memory _standardBridge)
        external
        initializer
    {
        standardBridge = _standardBridge;
        __Ownable_init();
    }

    /**
     * @inheritdoc IBridgeRegistry
     */
    function getStandardTokenBridge()
        external
        view
        override
        returns (BridgePair memory)
    {
        return standardBridge;
    }

    function getL2Token(address l1TokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return tokenMappings[l1TokenAddress];
    }

    /**
     * @inheritdoc IBridgeRegistry
     */
    function registerToken(address _l1TokenAddress, uint256 _l2TokenAddress)
        external
        override
    {
        // This will also ensure that tokenAddress is a contract
        try OwnableUpgradeable(_l1TokenAddress).owner() returns (
            address ownerAddress
        ) {
            require(
                ownerAddress == msg.sender,
                "sender is not owner of token contract"
            );
        } catch {
            revert("tokenAddress does not implement Ownable");
        }

        require(
            tokenMappings[_l1TokenAddress] == 0,
            "token already registered"
        );

        tokenMappings[_l1TokenAddress] = _l2TokenAddress;
    }

    /* This is a new function which is available after upgrade */

    function setNewVariable(uint256 _newVariabe) external {
        newVariable = _newVariabe;
    }

    function getNewVariable() external view returns (uint256) {
        return newVariable;
    }
}
