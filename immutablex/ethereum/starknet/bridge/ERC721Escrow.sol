// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IERC721Escrow.sol";

contract ERC721Escrow is
    Initializable,
    IERC721Escrow,
    IERC721Receiver,
    AccessControlUpgradeable
{
    bytes32 public constant WITHDRAWER_ROLE = bytes32("WITHDRAWER");

    function initialize() external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Prevent sending ERC721 tokens directly to this contract except from a WITHDRAWER
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        from;
        tokenId;
        data;
        if (hasRole(WITHDRAWER_ROLE, operator)) {
            return this.onERC721Received.selector;
        }
        return 0x00000000;
    }

    /**
     * @inheritdoc IERC721Escrow
     */
    function approveForWithdraw(address token, uint256 _tokenId)
        external
        override
        onlyRole(WITHDRAWER_ROLE)
    {
        IERC721(token).approve(msg.sender, _tokenId);
    }
}
