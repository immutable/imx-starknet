# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC2981_Mutable:
    func royaltyInfo(tokenId : Uint256, salePrice : Uint256) -> (
        receiver : felt, royaltyAmount : Uint256
    ):
    end

    func getDefaultRoyalty() -> (receiver : felt, feeBasisPoints : felt):
    end

    func setDefaultRoyalty(receiver : felt, feeBasisPoints : felt):
    end

    func resetDefaultRoyalty():
    end

    func setTokenRoyalty(tokenId : Uint256, receiver : felt, feeBasisPoints : felt):
    end

    func resetTokenRoyalty(tokenId : Uint256):
    end
end
