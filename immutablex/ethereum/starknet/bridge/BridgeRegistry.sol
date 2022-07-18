// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "immutablex/ethereum/starknet/core/libraries/StarknetUtilities.sol";
import "./interfaces/IBridgeRegistry.sol";

contract BridgeRegistry is Initializable, IBridgeRegistry, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using StarknetUtilities for uint256;

    /**
     * @dev mapping from L1 Token Address to L2 Token Address
     */
    mapping(address => uint256) private tokenMappings;

    /**
     * @dev details of the standard ERC721 Bridge
     */
    BridgePair private standardBridge;

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

    /**
     * @inheritdoc IBridgeRegistry
     */
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
        onlyOwner
    {
        require(
            _l2TokenAddress.isValidL2Address(),
            "_l2TokenAddress is out of range"
        );

        require(
            tokenMappings[_l1TokenAddress] == 0,
            "token already registered"
        );

        tokenMappings[_l1TokenAddress] = _l2TokenAddress;
        emit RegisterToken(msg.sender, _l1TokenAddress, _l2TokenAddress);
    }
}
