# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (token/erc721_token_metadata/library.cairo)

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le
from starkware.cairo.common.bool import TRUE, FALSE

from cairolib.array import arr_concat
from cairolib.shortstring import uint256_to_ss

from openzeppelin.introspection.ERC165 import ERC165

from immutablex.starknet.token.erc721.library import ERC721
from immutablex.starknet.utils.constants import IERC721_METADATA_ID

#
# Storage
#

@storage_var
func ERC721_base_token_uri_len() -> (res : felt):
end

@storage_var
func ERC721_base_token_uri(index : felt) -> (res : felt):
end

@storage_var
func ERC721_token_uri(token_id : Uint256, index : felt) -> (res : felt):
end

@storage_var
func ERC721_token_uri_len(token_id : Uint256) -> (res : felt):
end

namespace ERC721_Token_Metadata:
    #
    # Constructor
    #

    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        # register IERC721_Metadata
        ERC165.register_interface(IERC721_METADATA_ID)
        return ()
    end

    #
    # Getters
    #

    func token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (token_uri_len : felt, token_uri : felt*):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("ERC721_Token_Metadata: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(token_id)
        with_attr error_message("ERC721_Token_Metadata: URI query for nonexistent token"):
            assert exists = TRUE
        end

        let (local token_uri_len) = ERC721_token_uri_len.read(token_id)
        if token_uri_len != 0:
            # if the token_uri_len is not zero, that means the owner must have invoked setTokenURI for this NFT.
            # we therefore choose the specific tokenURI rather than using the baseURI
            let (local token_uri_value) = alloc()
            _token_uri(token_id, token_uri_len, token_uri_value)
            return (token_uri_len, token_uri_value)
        end

        let (local base_token_uri) = alloc()
        let (local base_token_uri_len) = ERC721_base_token_uri_len.read()
        if base_token_uri_len != 0:
            # We use the baseURI set by the owner, returning concat(baseURI,tokenId)
            _base_token_uri(base_token_uri_len, base_token_uri)

            let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id)
            let (token_uri_len, token_uri) = arr_concat(
                base_token_uri_len, base_token_uri, token_id_ss_len, token_id_ss
            )

            return (token_uri_len, token_uri)
        end

        # If both base_token_uri and token_uri are undefined, return empty array
        return (0, base_token_uri)
    end

    #
    # Setters
    #

    func set_base_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base_token_uri_len : felt, base_token_uri : felt*
    ):
        _set_base_token_uri(base_token_uri_len, base_token_uri)
        ERC721_base_token_uri_len.write(base_token_uri_len)
        return ()
    end

    func set_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, token_uri_len : felt, token_uri : felt*
    ):
        uint256_check(token_id)
        let (exists) = ERC721._exists(token_id)
        with_attr error_message("ERC721_Token_Metadata: set token URI for nonexistent token"):
            assert exists = TRUE
        end

        _set_token_uri(token_id, token_uri_len, token_uri)
        ERC721_token_uri_len.write(token_id, token_uri_len)
        return ()
    end

    func reset_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ):
        set_token_uri(token_id, 0, &[0])
        return ()
    end

    #
    # Internals
    #

    func _token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, token_uri_len : felt, token_uri_value : felt*
    ):
        if token_uri_len == 0:
            return ()
        end

        let (token_uri_value_at_index) = ERC721_token_uri.read(token_id, token_uri_len)
        assert [token_uri_value] = token_uri_value_at_index
        _token_uri(token_id, token_uri_len - 1, token_uri_value + 1)
        return ()
    end

    func _set_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, token_uri_len : felt, token_uri : felt*
    ):
        if token_uri_len == 0:
            return ()
        end

        ERC721_token_uri.write(token_id, token_uri_len, [token_uri])
        _set_token_uri(token_id, token_uri_len - 1, token_uri + 1)
        return ()
    end

    func _base_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base_token_uri_len : felt, base_token_uri : felt*
    ):
        if base_token_uri_len == 0:
            return ()
        end

        let (base) = ERC721_base_token_uri.read(base_token_uri_len)
        assert [base_token_uri] = base
        _base_token_uri(base_token_uri_len - 1, base_token_uri + 1)
        return ()
    end

    func _set_base_token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base_token_uri_len : felt, base_token_uri : felt*
    ):
        if base_token_uri_len == 0:
            return ()
        end

        ERC721_base_token_uri.write(base_token_uri_len, [base_token_uri])
        _set_base_token_uri(base_token_uri_len - 1, base_token_uri + 1)
        return ()
    end
end
