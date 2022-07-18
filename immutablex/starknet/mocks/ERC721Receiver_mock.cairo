# SPDX-License-Identifier: Apache 2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.ERC165 import ERC165

from immutablex.starknet.utils.constants import IERC721_RECEIVER_ID

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    ERC165.register_interface(IERC721_RECEIVER_ID)
    return ()
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@external
func onERC721Received(
    operator : felt, from_ : felt, tokenId : Uint256, data_len : felt, data : felt*
) -> (selector : felt):
    return (IERC721_RECEIVER_ID)
end
