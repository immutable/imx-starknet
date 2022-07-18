// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721Bridge {
    /**
     * @dev emitted on deposit
     */
    event Deposit(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev emitted on withdraw
     */
    event Withdraw(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds
    );

    /**
     * @dev event emitted when a deposit is cancelled and NFTs are returned
     */
    event DepositCancelInitiated(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev event emitted when a deposit is cancelled and NFTs are returned
     */
    event DepositCancelled(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev transfers the NFTs from the caller to the contract, then sends a message to StarkNet signalling a deposit
     */
    function deposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address
    ) external;

    /**
     * @dev transfers the NFTs from the contract to the caller after receiving the appropriate withdraw message from the user
     */
    function withdraw(
        IERC721 _token,
        uint256[] memory _tokenIds,
        address _recipient
    ) external;

    /**
     * @dev returns true if the NFT is ready to withdraw.
     * Used to prevent gas wasted on `withdraw`
     */
    function isWithdrawable(
        IERC721 _token,
        uint256[] memory _tokenIds,
        address withdrawer
    ) external view returns (bool);

    /**
     * @dev In the scenario that the deposit message was not
     * sent to L2 successfully, initiate cancel deposit to start the cancellation process
     */
    function initiateCancelDeposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce
    ) external;

    /**
     * @dev can be executed 5 days after intiateCancelDeposit. If successful, the caller will be returned their NFTs
     */
    function completeCancelDeposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce,
        address _recipient
    ) external;
}
