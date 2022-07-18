%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from immutablex.starknet.token.erc721.interfaces.IERC721 import IERC721
from immutablex.starknet.token.erc721_token_metadata.interfaces.IERC721_Token_Metadata import (
    IERC721_Token_Metadata,
)
from immutablex.starknet.token.erc721_contract_metadata.interfaces.IERC721_Contract_Metadata import (
    IERC721_Contract_Metadata,
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
func test_account_with_admin_role_can_set_base_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123
    let (base_uri : felt*) = alloc()
    assert base_uri[0] = 'https://ipfs.io/ipfs/this-is-a-'
    assert base_uri[1] = 'reasonable-sized-base-uri-set-b'
    assert base_uri[2] = 'y-the-owner/'

    test_utils.mint_token(contract_address, account, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC721_Token_Metadata.setBaseURI(contract_address, 3, base_uri)
    %{ stop_prank_callable() %}

    let (token_uri_len, token_uri) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    assert 4 = token_uri_len
    assert base_uri[0] = token_uri[0]
    assert base_uri[1] = token_uri[1]
    assert base_uri[2] = token_uri[2]
    assert '1' = token_uri[3]
    return ()
end

@view
func test_get_token_uri_for_token_with_undefined_token_uri_returns_empty_array{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let (token_uri_len, token_uri) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    assert 0 = token_uri_len
    return ()
end

@view
func test_revert_get_token_uri_for_nonexistent_token{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    %{ expect_revert(error_message="ERC721_Token_Metadata: URI query for nonexistent token") %}
    let (token_uri_len, token_uri) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    return ()
end

@view
func test_account_with_admin_role_can_set_token_uri_to_override_base_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123
    let (base_uri : felt*) = alloc()
    assert base_uri[0] = 'base-uri/'

    test_utils.mint_token(contract_address, account, Uint256(1, 0))
    test_utils.mint_token(contract_address, account, Uint256(2, 0))

    let (input_token_uri : felt*) = alloc()
    assert input_token_uri[0] = 'https://ipfs.io/ipfs/this-NFT-h'
    assert input_token_uri[1] = 'as-tokenId-set'

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC721_Token_Metadata.setBaseURI(contract_address, 1, base_uri)
    IERC721_Token_Metadata.setTokenURI(contract_address, Uint256(1, 0), 2, input_token_uri)
    %{ stop_prank_callable() %}

    # Token ID 1 should have a new token uri returned
    let (token_uri_len_1, token_uri_1) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    assert 2 = token_uri_len_1
    assert input_token_uri[0] = token_uri_1[0]
    assert input_token_uri[1] = token_uri_1[1]

    # Token ID 2 should still return the base uri + token id
    let (token_uri_len_2, token_uri_2) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(2, 0)
    )
    assert 2 = token_uri_len_2
    assert base_uri[0] = token_uri_2[0]
    assert '2' = token_uri_2[1]
    return ()
end

@view
func test_account_with_admin_role_can_reset_token_uri_to_use_base_uri_again{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123
    let (base_uri : felt*) = alloc()
    assert base_uri[0] = 'base-uri/'

    let (input_token_uri : felt*) = alloc()
    assert input_token_uri[0] = 'https://ipfs.io/ipfs/this-NFT-h'
    assert input_token_uri[1] = 'as-tokenId-set'

    test_utils.mint_token(contract_address, account, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC721_Token_Metadata.setBaseURI(contract_address, 1, base_uri)
    IERC721_Token_Metadata.setTokenURI(contract_address, Uint256(1, 0), 2, input_token_uri)
    IERC721_Token_Metadata.resetTokenURI(contract_address, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (token_uri_len, token_uri) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    assert 2 = token_uri_len
    assert base_uri[0] = token_uri[0]
    assert '1' = token_uri[1]
    return ()
end

@view
func test_can_set_ASCII_character_set_in_base_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123
    let (base_uri : felt*) = alloc()
    assert base_uri[0] = 'https://() !"[~^.Za1234567890Ab'
    assert base_uri[1] = 'cDseksicmab'

    test_utils.mint_token(contract_address, account, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC721_Token_Metadata.setBaseURI(contract_address, 2, base_uri)
    %{ stop_prank_callable() %}

    let (token_uri_len, token_uri) = IERC721_Token_Metadata.tokenURI(
        contract_address, Uint256(1, 0)
    )
    assert 3 = token_uri_len
    assert base_uri[0] = token_uri[0]
    assert base_uri[1] = token_uri[1]
    assert '1' = token_uri[2]
    return ()
end

@view
func test_account_with_admin_role_can_set_contract_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let (input_contract_uri : felt*) = alloc()
    assert input_contract_uri[0] = 'https://ipfs.io/ipfs/the-owner-'
    assert input_contract_uri[1] = 'is-trying-set-a-reasonable-size'
    assert input_contract_uri[2] = 'd-contract-uri/'

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC721_Contract_Metadata.setContractURI(contract_address, 3, input_contract_uri)
    %{ stop_prank_callable() %}

    let (contract_uri_len, contract_uri) = IERC721_Contract_Metadata.contractURI(contract_address)
    assert 3 = contract_uri_len
    assert input_contract_uri[0] = contract_uri[0]
    assert input_contract_uri[1] = contract_uri[1]
    assert input_contract_uri[2] = contract_uri[2]
    return ()
end

@view
func test_account_without_admin_role_cannot_set_contract_uri{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123
    let (input_contract_uri : felt*) = alloc()
    assert input_contract_uri[0] = 'https://ipfs.io/ipfs/the-owner-'
    assert input_contract_uri[1] = 'is-trying-set-a-reasonable-size'
    assert input_contract_uri[2] = 'd-contract-uri/'

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    IERC721_Contract_Metadata.setContractURI(contract_address, 3, input_contract_uri)
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
