// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "immutablex/ethereum/starknet/core/interfaces/IStarknetCore.sol";
import "immutablex/ethereum/starknet/core/libraries/StarknetUtilities.sol";
import "./interfaces/IERC721Bridge.sol";
import "./interfaces/IERC721Escrow.sol";
import "./interfaces/IBridgeRegistry.sol";

contract StandardERC721Bridge is
    Initializable,
    IERC721Bridge,
    OwnableUpgradeable
{
    using StarknetUtilities for uint256;
    using AddressUpgradeable for address;

    /**
     * @dev Cairo selector for the 'handle_deposit' function, used in deposit messages to L2
     */
    uint256 public constant DEPOSIT_HANDLER =
        1285101517810983806491589552491143496277809242732141897358598292095611420389;

    /**
     * @dev Number of array slots reserved when generating payload to starknet. The reserved slots
     * are for [ MESSAGING_type, SenderL1Address, TokenAddress, NumberOfTokenIds ]
     */
    uint256 public constant PAYLOAD_PREFIX_SIZE = 4;

    IBridgeRegistry private bridgeRegistry;
    IStarknetCore private starknetMessaging;
    IERC721Escrow private escrowContract;

    /**
     * @dev mapping from hash of a deposit to the depositor's address
     */
    mapping(bytes32 => address) private deposits;

    function initialize(
        IStarknetCore _starknetMessaging,
        IERC721Escrow _escrowContract
    ) external initializer {
        require(
            address(_starknetMessaging).isContract(),
            "starknet messaging is not a contract"
        );

        require(
            address(_escrowContract).isContract(),
            "erc721 escrow address is not a contract"
        );
        starknetMessaging = _starknetMessaging;
        escrowContract = _escrowContract;
        __Ownable_init();
    }

    /**
     * @dev return the L2 recipient of the message being sent to L2
     */
    function getL2MessageRecipient() internal view returns (uint256) {
        return bridgeRegistry.getStandardTokenBridge().l2BridgeAddress;
    }

    /**
     * @dev set the bridge registry address
     */
    function setBridgeRegistry(IBridgeRegistry _bridgeRegistry)
        external
        onlyOwner
    {
        require(
            address(_bridgeRegistry).isContract(),
            "bridge registry address is not a contract"
        );
        require(
            address(bridgeRegistry) == address(0),
            "bridge registry already set"
        );
        bridgeRegistry = _bridgeRegistry;
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function isWithdrawable(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        address withdrawer
    ) external view override returns (bool) {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadFromL2(
            _token,
            _tokenIds.length,
            withdrawer,
            l2TokenAddress
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // split uint256 into uint128 low and high
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(_tokenIds[i]);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                _tokenIds[i] >> 128
            );
        }

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                getL2MessageRecipient(),
                uint256(uint160(address(this))),
                payload.length,
                payload
            )
        );
        return starknetMessaging.l2ToL1Messages(msgHash) > 0;
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function deposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _token.transferFrom(msg.sender, address(escrowContract), tokenId);
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
        }

        uint256 starknetNonce = starknetMessaging.l1ToL2MessageNonce();

        bytes32 messageHash = starknetMessaging.sendMessageToL2(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload
        );

        deposits[messageHash] = msg.sender;

        emit Deposit(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            starknetNonce
        );
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function withdraw(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        address _recipient
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadFromL2(
            _token,
            _tokenIds.length,
            msg.sender,
            l2TokenAddress
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            escrowContract.approveForWithdraw(address(_token), tokenId);
            // split uint256 into uint128 low and high
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
            // optimistically transfer
            _token.transferFrom(address(escrowContract), _recipient, tokenId);
        }
        starknetMessaging.consumeMessageFromL2(
            getL2MessageRecipient(),
            payload
        );

        emit Withdraw(msg.sender, address(_token), _tokenIds);
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function initiateCancelDeposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
        }

        bytes32 msgHash = StarknetUtilities.getL1ToL2MsgHash(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            address(this),
            _nonce
        );

        require(
            deposits[msgHash] == msg.sender,
            "tokens were not deposited by sender"
        );

        starknetMessaging.startL1ToL2MessageCancellation(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            _nonce
        );

        emit DepositCancelInitiated(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            _nonce
        );
    }

    /**
     * @inheritdoc IERC721Bridge
     * @dev TODO Allow users to set their recipient address
     */
    function completeCancelDeposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce,
        address _recipient
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
            escrowContract.approveForWithdraw(address(_token), tokenId);
            _token.transferFrom(address(escrowContract), _recipient, tokenId);
        }

        bytes32 msgHash = StarknetUtilities.getL1ToL2MsgHash(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            address(this),
            _nonce
        );

        require(
            deposits[msgHash] == msg.sender,
            "tokens were not deposited by sender"
        );

        starknetMessaging.cancelL1ToL2Message(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            _nonce
        );

        // refund gas
        delete deposits[msgHash];

        emit DepositCancelled(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            _nonce
        );
    }

    function _createPayloadToL2(
        IERC721 _token,
        uint256 _numTokenIds,
        uint256 _senderL2Address,
        uint256 _l2TokenAddress
    ) private pure returns (uint256[] memory) {
        require(_numTokenIds > 0, "_tokenIds must not be empty");
        require(
            _senderL2Address.isValidL2Address(),
            "_senderL2Address is invalid"
        );
        uint256 tokenIdsLen = _numTokenIds << 1;

        uint256[] memory payload = new uint256[](
            PAYLOAD_PREFIX_SIZE + tokenIdsLen
        );
        payload[0] = _l2TokenAddress;
        payload[1] = _senderL2Address;
        payload[2] = uint256(uint160(address(_token)));
        payload[3] = tokenIdsLen;
        return payload;
    }

    function _createPayloadFromL2(
        IERC721 _token,
        uint256 _numTokenIds,
        address _senderL1Address,
        uint256 _l2TokenAddress
    ) private pure returns (uint256[] memory) {
        require(_numTokenIds > 0, "_tokenIds must not be empty");

        uint256 tokenIdsLen = _numTokenIds << 1;

        uint256[] memory payload = new uint256[](
            PAYLOAD_PREFIX_SIZE + tokenIdsLen
        );
        payload[0] = _l2TokenAddress;
        payload[1] = uint256(uint160(_senderL1Address));
        payload[2] = uint256(uint160(address(_token)));
        payload[3] = tokenIdsLen;
        return payload;
    }

    function getL2TokenOrRevert(address _l1Token)
        internal
        view
        returns (uint256)
    {
        uint256 l2TokenAddress = bridgeRegistry.getL2Token(_l1Token);
        require(l2TokenAddress != 0, "token is not registered");
        return l2TokenAddress;
    }
}
