# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721_Token_Metadata:
    func tokenURI(tokenId : Uint256) -> (tokenURI_len : felt, tokenURI : felt*):
    end

    func setBaseURI(base_token_uri_len : felt, base_token_uri : felt*):
    end

    func setTokenURI(tokenId : Uint256, tokenURI_len : felt, tokenURI : felt*):
    end

    func resetTokenURI(tokenId : Uint256):
    end
end
