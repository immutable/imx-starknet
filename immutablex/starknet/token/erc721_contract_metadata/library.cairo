# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (token/erc721_contract_metadata/library.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc

#
# Storage
#

@storage_var
func ERC721_contract_uri_len() -> (res : felt):
end

@storage_var
func ERC721_contract_uri(index : felt) -> (res : felt):
end

namespace ERC721_Contract_Metadata:
    #
    # Getters
    #

    func contract_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        contract_uri_len : felt, contract_uri : felt*
    ):
        alloc_locals
        let (local contract_uri : felt*) = alloc()
        let (local contract_uri_len : felt) = ERC721_contract_uri_len.read()
        _contract_uri(contract_uri_len, contract_uri)
        return (contract_uri_len, contract_uri)
    end

    #
    # Setters
    #

    func set_contract_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contract_uri_len : felt, contract_uri : felt*
    ):
        _set_contract_uri(contract_uri_len, contract_uri)
        ERC721_contract_uri_len.write(contract_uri_len)
        return ()
    end

    #
    # Internals
    #

    func _set_contract_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contract_uri_len : felt, contract_uri : felt*
    ):
        if contract_uri_len == 0:
            return ()
        end
        ERC721_contract_uri.write(contract_uri_len, [contract_uri])
        _set_contract_uri(contract_uri_len - 1, contract_uri + 1)
        return ()
    end

    func _contract_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contract_uri_len : felt, contract_uri : felt*
    ):
        if contract_uri_len == 0:
            return ()
        end
        let (base) = ERC721_contract_uri.read(contract_uri_len)
        assert [contract_uri] = base
        _contract_uri(contract_uri_len - 1, contract_uri + 1)
        return ()
    end
end
