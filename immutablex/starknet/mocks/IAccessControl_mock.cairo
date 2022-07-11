# SPDX-License-Identifier: Apache 2.0

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccessControl:
    func has_role(role : felt, account : felt) -> (res : felt):
    end

    func get_role_admin(role : felt) -> (role_admin : felt):
    end

    func grant_role(role : felt, account : felt):
    end

    func revoke_role(role : felt, account : felt):
    end

    func renounce_role(role : felt, account : felt):
    end

    func set_role_admin(role : felt, admin_role : felt):
    end
end
