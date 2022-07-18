// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "immutablex/ethereum/starknet/bridge/interfaces/IERC721Bridge.sol";
import "hardhat/console.sol";

contract ERC721AttackerMock is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("TestNFT", "TEST") Ownable() {}

    function mint(address to) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        return newItemId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        from;
        to;
        tokenId;
        IERC721Bridge(msg.sender).deposit(this, new uint256[](1), 123456);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        from;
        to;
        tokenId;
        IERC721Bridge(msg.sender).deposit(this, new uint256[](1), 123456);
    }

    function mintBatch(address to, uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            mint(to);
        }
    }
}
