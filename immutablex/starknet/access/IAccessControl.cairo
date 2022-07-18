# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (access/IAccessControl.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccessControl:
    func hasRole(role : felt, account : felt) -> (res : felt):
    end

    func getRoleAdmin(role : felt) -> (role_admin : felt):
    end

    func grantRole(role : felt, account : felt):
    end

    func revokeRole(role : felt, account : felt):
    end

    func renounceRole(role : felt, account : felt):
    end
end
