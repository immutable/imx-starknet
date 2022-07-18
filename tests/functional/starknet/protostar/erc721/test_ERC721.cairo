%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from immutablex.starknet.token.erc721.interfaces.IERC721 import IERC721
from immutablex.starknet.token.erc721_token_metadata.interfaces.IERC721_Token_Metadata import (
    IERC721_Token_Metadata,
)
from immutablex.starknet.access.IAccessControl import IAccessControl
from immutablex.starknet.bridge.interfaces.IERC721_Bridgeable import IERC721_Bridgeable
from tests.utils.test_constants import TRUE, FALSE

const NAME = 'Rezs Raging Rhinos'
const SYMBOL = 'REZ'
const OWNER = 123456
const ROYALTY_RECIPIENT = 567890
const ROYALTY_FEE_BASIS_POINTS = 2000

@view
func __setup__():
    %{
        context.contract_address = deploy_contract("./immutablex/starknet/token/erc721/presets/ERC721_Full.cairo", 
            [
                ids.NAME, ids.SYMBOL, ids.OWNER, ids.ROYALTY_RECIPIENT, ids.ROYALTY_FEE_BASIS_POINTS
            ]
        ).contract_address
    %}
    return ()
end

@view
func test_get_name{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (name) = IERC721.name(contract_address)
    assert NAME = name
    return ()
end

@view
func test_get_symbol{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (symbol) = IERC721.symbol(contract_address)
    assert SYMBOL = symbol
    return ()
end

@view
func test_has_role{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (has_default_admin_role) = IAccessControl.hasRole(contract_address, 0, OWNER)
    assert TRUE = has_default_admin_role

    let (has_minter_role) = IAccessControl.hasRole(contract_address, 'MINTER_ROLE', OWNER)
    assert FALSE = has_minter_role
    return ()
end

@view
func test_account_with_minter_role_can_mint_tokens{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    test_utils.mint_token(contract_address, account, Uint256(1, 0))
    test_utils.mint_token(contract_address, account, Uint256(2, 0))

    let (balance) = IERC721.balanceOf(contract_address, account)
    assert Uint256(2, 0) = balance
    return ()
end

@view
func test_account_without_minter_role_cannot_mint_tokens{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: caller is missing role 93433465781963921833282629") %}
    IERC721_Bridgeable.permissionedMint(contract_address, account, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_token_owner_can_transferFrom_their_NFT{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account_1 = 123
    let account_2 = 456

    test_utils.mint_token(contract_address, account_1, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.account_1, context.contract_address) %}
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (token_owner) = IERC721.ownerOf(contract_address, Uint256(1, 0))
    assert account_2 = token_owner
    return ()
end

@view
func test_token_owner_can_approve_another_address_to_transfer_their_NFT{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account_1 = 123
    let account_2 = 456

    test_utils.mint_token(contract_address, account_1, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.account_1, context.contract_address) %}
    IERC721.approve(contract_address, account_2, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (approved) = IERC721.getApproved(contract_address, Uint256(1, 0))
    assert account_2 = approved

    %{ stop_prank_callable = start_prank(ids.account_2, context.contract_address) %}
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (token_owner) = IERC721.ownerOf(contract_address, Uint256(1, 0))
    assert account_2 = token_owner
    return ()
end

@view
func test_token_owner_can_approveForAll_another_address_to_transfer_all_their_NFTs{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account_1 = 123
    let account_2 = 456

    test_utils.mint_token(contract_address, account_1, Uint256(1, 0))
    test_utils.mint_token(contract_address, account_1, Uint256(2, 0))
    test_utils.mint_token(contract_address, account_1, Uint256(3, 0))

    %{ stop_prank_callable = start_prank(ids.account_1, context.contract_address) %}
    IERC721.setApprovalForAll(contract_address, account_2, TRUE)
    %{ stop_prank_callable() %}

    let (is_approved) = IERC721.isApprovedForAll(contract_address, account_1, account_2)
    assert TRUE = is_approved

    %{ stop_prank_callable = start_prank(ids.account_2, context.contract_address) %}
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(1, 0))
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(2, 0))
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(3, 0))
    %{ stop_prank_callable() %}

    let (balance) = IERC721.balanceOf(contract_address, account_1)
    assert Uint256(0, 0) = balance
    let (balance) = IERC721.balanceOf(contract_address, account_2)
    assert Uint256(3, 0) = balance
    return ()
end

@view
func test_token_owner_can_revoke_approval_by_approving_zero_address{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account_1 = 123
    let account_2 = 456

    test_utils.mint_token(contract_address, account_1, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.account_1, context.contract_address) %}
    IERC721.approve(contract_address, account_2, Uint256(1, 0))
    IERC721.approve(contract_address, 0, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (approved) = IERC721.getApproved(contract_address, Uint256(1, 0))
    assert 0 = approved

    %{ stop_prank_callable = start_prank(ids.account_2, context.contract_address) %}
    %{ expect_revert(error_message="ERC721: either is not approved or the caller is the zero address") %}
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_token_owner_can_revoke_approveForAll{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account_1 = 123
    let account_2 = 456

    test_utils.mint_token(contract_address, account_1, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.account_1, context.contract_address) %}
    IERC721.setApprovalForAll(contract_address, account_2, TRUE)
    IERC721.setApprovalForAll(contract_address, account_2, FALSE)
    %{ stop_prank_callable() %}

    let (is_approved) = IERC721.isApprovedForAll(contract_address, account_1, account_2)
    assert 0 = is_approved

    %{ stop_prank_callable = start_prank(ids.account_2, context.contract_address) %}
    %{ expect_revert(error_message="ERC721: either is not approved or the caller is the zero address") %}
    IERC721.transferFrom(contract_address, account_1, account_2, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end

namespace test_utils:
    func mint_token{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        contract_address : felt, to : felt, token_id : Uint256
    ):
        %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
        IAccessControl.grantRole(contract_address, 'MINTER_ROLE', OWNER)
        IERC721_Bridgeable.permissionedMint(contract_address, to, token_id)
        %{ stop_prank_callable() %}
        return ()
    end
end
