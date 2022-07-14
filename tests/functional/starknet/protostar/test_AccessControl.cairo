%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from immutablex.starknet.mocks.IAccessControl_mock import IAccessControl
from tests.utils.test_constants import TRUE, FALSE

const DEFAULT_ADMIN_ACCOUNT = 123456
const DEFAULT_ADMIN_ROLE = 0

@view
func __setup__():
    %{ context.contract_address = deploy_contract("./immutablex/starknet/mocks/AccessControl_mock.cairo", [ids.DEFAULT_ADMIN_ACCOUNT]).contract_address %}
    return ()
end

@view
func test_default_admin_should_have_default_admin_role{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (has_admin_role) = IAccessControl.has_role(
        contract_address, DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ACCOUNT
    )
    assert TRUE = has_admin_role
    return ()
end

@view
func test_non_default_admin_should_not_have_default_admin_role{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let non_admin_account = 123

    let (has_admin_role) = IAccessControl.has_role(
        contract_address, DEFAULT_ADMIN_ROLE, non_admin_account
    )
    assert FALSE = has_admin_role
    return ()
end

@view
func test_default_admin_can_grant_a_new_role_to_an_account{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123

    %{ expect_events({"name": "RoleGranted", "data": [ids.minter_role, ids.account, ids.DEFAULT_ADMIN_ACCOUNT]}) %}
    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.grant_role(contract_address, minter_role, account)
    %{ stop_prank_callable() %}

    let (has_minter_role) = IAccessControl.has_role(contract_address, minter_role, account)
    assert TRUE = has_minter_role
    return ()
end

@view
func test_non_role_admin_cannot_grant_new_roles{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: account is missing role") %}
    IAccessControl.grant_role(contract_address, minter_role, account)
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_role_admin_can_revoke_roles_from_account{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123

    %{ expect_events({"name": "RoleRevoked", "data": [ids.minter_role, ids.account, ids.DEFAULT_ADMIN_ACCOUNT]}) %}
    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}

    IAccessControl.grant_role(contract_address, minter_role, account)
    let (has_minter_role) = IAccessControl.has_role(contract_address, minter_role, account)
    assert TRUE = has_minter_role

    IAccessControl.revoke_role(contract_address, minter_role, account)
    let (has_minter_role) = IAccessControl.has_role(contract_address, minter_role, account)
    assert FALSE = has_minter_role

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_non_role_admin_cannot_revoke_roles_from_account{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: account is missing role") %}

    IAccessControl.revoke_role(contract_address, minter_role, account)

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_default_admin_can_set_a_role_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let minter_role_admin = 'MINTER_ROLE_ADMIN'

    let (role_admin) = IAccessControl.get_role_admin(contract_address, minter_role)
    assert DEFAULT_ADMIN_ROLE = role_admin

    %{ expect_events({"name": "RoleAdminChanged", "data": [ids.minter_role, ids.DEFAULT_ADMIN_ROLE, ids.minter_role_admin]}) %}
    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.set_role_admin(contract_address, minter_role, minter_role_admin)
    %{ stop_prank_callable() %}

    let (role_admin) = IAccessControl.get_role_admin(contract_address, minter_role)
    assert minter_role_admin = role_admin
    return ()
end

@view
func test_non_role_admin_cannot_set_role_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let minter_role_admin = 'MINTER_ROLE_ADMIN'
    let account = 123

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: account is missing role") %}

    IAccessControl.set_role_admin(contract_address, minter_role, minter_role_admin)

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_default_admin_cannot_grant_role_for_which_another_role_admin_has_been_defined{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let minter_role_admin = 'MINTER_ROLE_ADMIN'
    let account = 123

    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}

    IAccessControl.set_role_admin(contract_address, minter_role, minter_role_admin)
    %{ expect_revert(error_message="AccessControl: account is missing role") %}
    IAccessControl.grant_role(contract_address, minter_role, account)

    %{ stop_prank_callable() %}

    return ()
end

@view
func test_role_admin_can_manage_roles_for_which_they_are_an_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let minter_role_admin = 'MINTER_ROLE_ADMIN'
    let minter_role_account = 123
    let account = 456

    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.set_role_admin(contract_address, minter_role, minter_role_admin)
    IAccessControl.grant_role(contract_address, minter_role_admin, minter_role_account)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.minter_role_account, context.contract_address) %}

    IAccessControl.grant_role(contract_address, minter_role, account)
    let (has_minter_role) = IAccessControl.has_role(contract_address, minter_role, account)
    assert TRUE = has_minter_role

    IAccessControl.revoke_role(contract_address, minter_role, account)
    let (has_minter_role2) = IAccessControl.has_role(contract_address, minter_role, account)
    assert FALSE = has_minter_role2

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_role_admin_cannot_manage_roles_for_which_it_is_not_an_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let minter_role_admin = 'MINTER_ROLE_ADMIN'
    let minter_role_account = 123
    let account = 456

    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.set_role_admin(contract_address, minter_role, minter_role_admin)
    IAccessControl.grant_role(contract_address, minter_role_admin, minter_role_account)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.minter_role_account, context.contract_address) %}

    %{ expect_revert(error_message="AccessControl: account is missing role") %}
    IAccessControl.grant_role(contract_address, DEFAULT_ADMIN_ROLE, account)
    %{ expect_revert(error_message="AccessControl: account is missing role") %}
    IAccessControl.revoke_role(contract_address, DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ACCOUNT)

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_role_member_can_renounce_role_for_self{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123

    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.grant_role(contract_address, minter_role, account)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    IAccessControl.renounce_role(contract_address, minter_role, account)
    %{ stop_prank_callable() %}

    let (has_minter_role) = IAccessControl.has_role(contract_address, minter_role, account)
    assert FALSE = has_minter_role
    return ()
end

@view
func test_role_member_cannot_renounce_role_for_other_accounts{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let minter_role = 'MINTER_ROLE'
    let account = 123
    let account2 = 456

    %{ stop_prank_callable = start_prank(ids.DEFAULT_ADMIN_ACCOUNT, context.contract_address) %}
    IAccessControl.grant_role(contract_address, minter_role, account)
    IAccessControl.grant_role(contract_address, minter_role, account2)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="AccessControl: can only renounce roles for self") %}
    IAccessControl.renounce_role(contract_address, minter_role, account2)
    %{ stop_prank_callable() %}
    return ()
end
