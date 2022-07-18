# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (erc2981/interfaces/IERC2981.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC2981:
    func royaltyInfo(tokenId : Uint256, salePrice : Uint256) -> (
        receiver : felt, royaltyAmount : Uint256
    ):
    end
end
