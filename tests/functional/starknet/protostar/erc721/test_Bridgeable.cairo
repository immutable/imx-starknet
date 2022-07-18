%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from immutablex.starknet.token.erc721.interfaces.IERC721 import IERC721
from immutablex.starknet.access.IAccessControl import IAccessControl
from immutablex.starknet.bridge.interfaces.IERC721_Bridgeable import IERC721_Bridgeable
from tests.utils.test_constants import TRUE, FALSE

const NAME = 'Rezs Raging Rhinos'
const SYMBOL = 'REZ'
const OWNER = 123456
const ROYALTY_RECIPIENT = 567890
const ROYALTY_FEE_BASIS_POINTS = 2000

const MOCK_BRIDGE_ADDRESS = 1234567890

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
func test_default_admin_can_grant_a_bridge_minter_and_burner_roles{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (has_minter_role) = IAccessControl.hasRole(
        contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS
    )
    assert FALSE = has_minter_role
    let (has_burner_role) = IAccessControl.hasRole(
        contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS
    )
    assert FALSE = has_burner_role

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IAccessControl.grantRole(contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS)
    IAccessControl.grantRole(contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS)
    %{ stop_prank_callable() %}

    let (has_minter_role) = IAccessControl.hasRole(
        contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS
    )
    assert TRUE = has_minter_role
    let (has_burner_role) = IAccessControl.hasRole(
        contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS
    )
    assert TRUE = has_burner_role
    return ()
end

@view
func test_unauthorized_bridge_address_cannot_call_permissioned_functions{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.MOCK_BRIDGE_ADDRESS, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: caller is missing role 93433465781963921833282629") %}
    IERC721_Bridgeable.permissionedMint(contract_address, account, Uint256(1, 0))
    %{ expect_revert(error_message="AccessControl: caller is missing role 80192023518628167264717893") %}
    IERC721_Bridgeable.permissionedBurn(contract_address, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_bridge_with_minter_role_can_call_permissionedMint{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IAccessControl.grantRole(contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS)
    %{ stop_prank_callable() %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.MOCK_BRIDGE_ADDRESS, context.contract_address) %}
    IERC721_Bridgeable.permissionedMint(contract_address, account, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (owner) = IERC721.ownerOf(contract_address, Uint256(1, 0))
    assert account = owner
    return ()
end

@view
func test_bridge_with_burner_role_can_call_permissionedBurn{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IAccessControl.grantRole(contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS)
    IAccessControl.grantRole(contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS)
    %{ stop_prank_callable() %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.MOCK_BRIDGE_ADDRESS, context.contract_address) %}
    IERC721_Bridgeable.permissionedMint(contract_address, account, Uint256(1, 0))
    IERC721_Bridgeable.permissionedBurn(contract_address, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (balance) = IERC721.balanceOf(contract_address, account)
    assert Uint256(0, 0) = balance
    return ()
end

@view
func test_default_admin_can_revoke_bridge_roles{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IAccessControl.grantRole(contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS)
    IAccessControl.grantRole(contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS)

    IAccessControl.revokeRole(contract_address, 'MINTER_ROLE', MOCK_BRIDGE_ADDRESS)
    IAccessControl.revokeRole(contract_address, 'BURNER_ROLE', MOCK_BRIDGE_ADDRESS)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.MOCK_BRIDGE_ADDRESS, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: caller is missing role 93433465781963921833282629") %}
    IERC721_Bridgeable.permissionedMint(contract_address, account, Uint256(1, 0))
    %{ expect_revert(error_message="AccessControl: caller is missing role 80192023518628167264717893") %}
    IERC721_Bridgeable.permissionedBurn(contract_address, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end
