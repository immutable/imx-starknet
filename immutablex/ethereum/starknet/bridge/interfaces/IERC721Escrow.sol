// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721Escrow {
    /**
     * @dev callable by an address with the WITHDRAWER role, initially only the StandardERC721Bridge
     */
    function approveForWithdraw(address token, uint256 _tokenId) external;
}
