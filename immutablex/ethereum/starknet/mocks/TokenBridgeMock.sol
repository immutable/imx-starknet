// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.2.1
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract TokenBridgeMock {
    function deposit(address _tokenAddress, uint256[] memory _tokenIds)
        external
        virtual
    {
        console.log("executing depost");
    }

    function withdraw(address tokenAddress, uint256[] memory _tokenIds)
        external
        virtual
    {
        console.log("calling withdraw");
    }
}
