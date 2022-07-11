# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.1.0 (access/AccessControl.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.introspection.ERC165 import ERC165

from immutablex.starknet.utils.constants import IACCESSCONTROL_ID

#
# Constants
#

const DEFAULT_ADMIN_ROLE = 0x00

#
# Events
#

@event
func RoleGranted(role : felt, account : felt, sender : felt):
end

@event
func RoleRevoked(role : felt, account : felt, sender : felt):
end

@event
func RoleAdminChanged(role : felt, previous_admin_role : felt, new_admin_role):
end

#
# Storage
#

@storage_var
func AccessControl_role_members(role : felt, account : felt) -> (res : felt):
end

@storage_var
func AccessControl_role_admin(role : felt) -> (admin_role : felt):
end

namespace AccessControl:
    #
    # Initializer
    #

    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        default_admin : felt
    ):
        AccessControl._grant_role(DEFAULT_ADMIN_ROLE, default_admin)
        ERC165.register_interface(IACCESSCONTROL_ID)
        return ()
    end

    #
    # Checks
    #

    # @dev Modifier that checks that an account has a specific role. Reverts
    # with a standardized message including the required role.
    func only_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(role : felt):
        let (caller) = get_caller_address()
        let (res) = has_role(role, caller)
        with_attr error_message("AccessControl: account is missing role"):
            assert res = TRUE
        end
        return ()
    end

    #
    # Getters
    #

    # @dev Returns 1 (TRUE) if `account` has been granted `role`.
    func has_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ) -> (res : felt):
        let (_has_role) = AccessControl_role_members.read(role, account)
        return (_has_role)
    end

    # @dev Returns the admin role that controls `role`. See {grantRole} and
    # {revokeRole}.
    #
    # To change a role's admin, use {_setRoleAdmin}.
    func get_role_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt
    ) -> (role_admin : felt):
        let (role_admin) = AccessControl_role_admin.read(role)
        return (role_admin)
    end

    #
    # Setters
    #

    # @dev Grants `role` to `account`.
    #
    # If `account` had not been already granted `role`, emits a {RoleGranted}
    # event.
    #
    # Requirements:
    #
    # - the caller must have ``role``'s admin role.
    func grant_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ):
        let (role_admin) = get_role_admin(role)
        only_role(role_admin)
        _grant_role(role, account)
        return ()
    end

    # @dev Revokes `role` from `account`.
    #
    # If `account` had been granted `role`, emits a {RoleRevoked} event.
    #
    # Requirements:
    #
    # - the caller must have ``role``'s admin role.
    func revoke_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ):
        let (role_admin) = get_role_admin(role)
        only_role(role_admin)
        _revoke_role(role, account)
        return ()
    end

    # @dev Revokes `role` from the calling account.
    #
    # Roles are often managed via {grant_role} and {revoke_role}: this function's
    # purpose is to provide a mechanism for accounts to lose their privileges
    # if they are compromised (such as when a trusted device is misplaced).
    #
    # If the calling account had been revoked `role`, emits a {RoleRevoked}
    # event.
    #
    # Requirements:
    #
    # - the caller must be `account`.
    func renounce_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ):
        with_attr error_message("AccessControl: can only renounce roles for self"):
            let (caller) = get_caller_address()
            assert caller = account
        end
        _revoke_role(role, account)
        return ()
    end

    #
    # Internal
    #

    # @dev Grants `role` to `account`.
    #
    # Internal function without access restriction.
    # Emits a {RoleRevoked} event.
    #
    # [WARNING]
    # ====
    # This function should only be called outside of this contract from the constructor when setting
    # up the initial roles for the system.
    #
    # Using this function in any other way is effectively circumventing the admin
    # system imposed by {AccessControl}.
    # ====
    func _grant_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ):
        let (_has_role) = has_role(role, account)
        if _has_role == TRUE:
            return ()
        end

        AccessControl_role_members.write(role, account, TRUE)

        let (caller) = get_caller_address()
        RoleGranted.emit(role, account, caller)
        return ()
    end

    # @dev Revokes `role` from `account`.
    #
    # Internal function without access restriction.
    # Emits a {RoleRevoked} event.
    func _revoke_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, account : felt
    ):
        let (_has_role) = has_role(role, account)
        if _has_role == FALSE:
            return ()
        end

        AccessControl_role_members.write(role, account, FALSE)

        let (caller) = get_caller_address()
        RoleRevoked.emit(role, account, caller)
        return ()
    end

    # @dev Sets `adminRole` as ``role``'s admin role.
    #
    # Internal function without access restriction.
    # Emits a {RoleAdminChanged} event.
    func _set_role_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        role : felt, admin_role : felt
    ):
        let (prev_admin_role) = get_role_admin(role)
        AccessControl_role_admin.write(role, admin_role)
        RoleAdminChanged.emit(role, prev_admin_role, admin_role)
        return ()
    end
end
