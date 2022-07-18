# SPDX-License-Identifier: MIT
# Immutable Cairo Contracts v0.2.1

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func balanceOf(owner : felt) -> (balance : Uint256):
    end

    func ownerOf(tokenId : Uint256) -> (owner : felt):
    end

    func safeTransferFrom(
        from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
    ):
    end

    func transferFrom(from_ : felt, to : felt, tokenId : Uint256):
    end

    func approve(to : felt, tokenId : Uint256):
    end

    func setApprovalForAll(operator : felt, approved : felt):
    end

    func getApproved(tokenId : Uint256) -> (approved : felt):
    end

    func isApprovedForAll(owner : felt, operator : felt) -> (isApproved : felt):
    end
end
