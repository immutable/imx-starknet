%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.starknet.common.messages import send_message_to_l1
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable import Ownable

from immutablex.starknet.token.erc721.interfaces.IERC721 import IERC721
from immutablex.starknet.bridge.interfaces.IERC721_Bridgeable import IERC721_Bridgeable

const PAYLOAD_PREFIX_SIZE = 4

@storage_var
func _l1_bridge() -> (l1_bridge : felt):
end

@storage_var
func _l2_to_l1_addresses(l2_address : felt) -> (l1_address : felt):
end

# TODO: l1 handler to register pair of addresses, ownable + ability to change l1 bridge/upgrade?
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    Ownable.initializer(owner)
    return ()
end

#
# Getters
#

@view
func get_l1_bridge{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    l1_bridge : felt
):
    let (l1_bridge) = _l1_bridge.read()
    return (l1_bridge)
end

@view
func get_l1_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    l2_address : felt
) -> (l1_address : felt):
    let (l1_address) = _l2_to_l1_addresses.read(l2_address)
    return (l1_address)
end

#
# External
#

@external
func set_l1_bridge{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    l1_bridge_address : felt
):
    Ownable.assert_only_owner()
    _l1_bridge.write(l1_bridge_address)
    return ()
end

@external
func initiate_withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    l2_token_address : felt, l2_token_ids_len : felt, l2_token_ids : Uint256*, l1_claimant : felt
):
    alloc_locals
    # construct message payload
    let (l1_token_address) = _l2_to_l1_addresses.read(l2_token_address)
    let (payload : felt*) = alloc()
    assert payload[0] = l2_token_address
    assert payload[1] = l1_claimant
    assert payload[2] = l1_token_address
    assert payload[3] = l2_token_ids_len * 2

    # loop through each token and call permissionedBurn
    let (caller) = get_caller_address()
    _withdraw(
        l2_token_address, l2_token_ids_len, l2_token_ids, caller, payload + PAYLOAD_PREFIX_SIZE
    )

    # send message to L1 with payload
    # note: two felts per Uint256 so bigger payload size
    let (l1_bridge_address) = get_l1_bridge()
    send_message_to_l1(
        to_address=l1_bridge_address,
        payload_size=PAYLOAD_PREFIX_SIZE + (l2_token_ids_len * 2),
        payload=payload,
    )
    return ()
end

#
# L1 Handler
#

@l1_handler
func handle_deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_address : felt,
    l2_token_address : felt,
    l2_receiver_address : felt,
    l1_token_address : felt,
    l1_token_ids_len : felt,
    l1_token_ids : felt*,
):
    alloc_locals
    # check message source
    with_attr error_message("StandardERC721Bridge: message received from invalid source"):
        let (l1_bridge_address) = _l1_bridge.read()
        assert from_address = l1_bridge_address
    end

    let (saved_l1_token_address) = get_l1_address(l2_token_address)
    if saved_l1_token_address == 0:
        _l2_to_l1_addresses.write(l2_token_address, l1_token_address)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    # for each token, permissionedMint to l2_receiver_address
    _deposit(l2_token_address, l2_receiver_address, l1_token_ids_len, l1_token_ids)
    return ()
end

#
# Internal
#

func _deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt, receiver : felt, token_ids_len : felt, token_ids : felt*
):
    if token_ids_len == 0:
        return ()
    end

    with_attr error_message("StandardERC721Bridge: invalid token id"):
        # each token id is a Uint256 and is represented by two consecutive felts (low, high) in token_ids
        let token_id_low = [token_ids]
        let token_id_high = [token_ids + 1]
        let token_id : Uint256 = cast((low=token_id_low, high=token_id_high), Uint256)
        uint256_check(token_id)
    end

    with_attr error_message("StandardERC721Bridge: failed to permissionedMint token to receiver"):
        IERC721_Bridgeable.permissionedMint(token_address, receiver, token_id)
    end

    _deposit(token_address, receiver, token_ids_len - 2, token_ids + 2)
    return ()
end

func _withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt, token_ids_len : felt, token_ids : Uint256*, caller : felt, payload : felt*
):
    if token_ids_len == 0:
        return ()
    end

    let token_id = [token_ids]
    uint256_check(token_id)

    with_attr error_message("StandardERC721Bridge: caller is not owner of given token"):
        let (owner) = IERC721.ownerOf(token_address, token_id)
        assert owner = caller
    end

    with_attr error_message("StandardERC721Bridge: failed to call permissionedBurn for token"):
        IERC721_Bridgeable.permissionedBurn(token_address, token_id)
    end
    # each token id is a Uint256 so we save two felts (low, high) per token id in the payload
    assert [payload] = token_id.low
    assert [payload + 1] = token_id.high
    _withdraw(token_address, token_ids_len - 1, token_ids + 1, caller, payload + 2)
    return ()
end
