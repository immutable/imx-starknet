# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (erc2981/mutable.cairo)

# This is a fully mutable implementation of EIP2981, where the royalty info can changed at any
# point in time, and custom per-token royalties can be defined to override a contract-wide
# royalty.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le_felt
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_le,
    uint256_check,
    uint256_mul,
    uint256_unsigned_div_rem,
)

from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.security.safemath import SafeUint256

from immutablex.starknet.utils.constants import IERC2981_ID

const FEE_DENOMINATOR = 10000

# The royalty percentage is expressed in basis points
# i.e. fee_basis_points of 123 = 1.23%, 10000 = 100%
struct RoyaltyInfo:
    member receiver : felt
    member fee_basis_points : felt
end

@storage_var
func ERC2981_Mutable_default_royalty_info() -> (default_royalty_info : RoyaltyInfo):
end

@storage_var
func ERC2981_Mutable_token_royalty_info(token_id : Uint256) -> (token_royalty_info : RoyaltyInfo):
end

namespace ERC2981_Mutable:
    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        ERC165.register_interface(IERC2981_ID)
        return ()
    end

    func royalty_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, sale_price : Uint256
    ) -> (receiver : felt, royalty_amount : Uint256):
        alloc_locals
        with_attr error_message("ERC2981_Mutable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        let (royalty) = ERC2981_Mutable_token_royalty_info.read(token_id)
        if royalty.receiver == 0:
            let (royalty) = ERC2981_Mutable_default_royalty_info.read()
        end

        local royalty : RoyaltyInfo = royalty

        # royalty_amount = sale_price * fee_basis_points / 10000
        let (x : Uint256) = SafeUint256.mul(sale_price, Uint256(royalty.fee_basis_points, 0))
        let (royalty_amount : Uint256, _) = SafeUint256.div_rem(x, Uint256(FEE_DENOMINATOR, 0))

        return (royalty.receiver, royalty_amount)
    end

    # This function should not be used to calculate the royalty amount and simply exposes royalty info for display purposes.
    # Use ERC2981_Mutable_royaltyInfo to calculate royalty fee amounts for orders as per EIP2981.
    func get_default_royalty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (receiver : felt, fee_basis_points : felt):
        let (royalty) = ERC2981_Mutable_default_royalty_info.read()
        return (royalty.receiver, royalty.fee_basis_points)
    end

    func set_default_royalty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        receiver : felt, fee_basis_points : felt
    ):
        with_attr error_message(
                "ERC2981_Mutable: fee_basis_points exceeds fee denominator (10000)"):
            assert_le_felt(fee_basis_points, FEE_DENOMINATOR)
        end

        ERC2981_Mutable_default_royalty_info.write(RoyaltyInfo(receiver, fee_basis_points))
        return ()
    end

    func reset_default_royalty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        ERC2981_Mutable_default_royalty_info.write(RoyaltyInfo(0, 0))
        return ()
    end

    # If a token royalty for a token is set then it takes precedence over (overrides) the default royalty
    func set_token_royalty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, receiver : felt, fee_basis_points : felt
    ):
        with_attr error_message("ERC2981_Mutable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end
        with_attr error_message(
                "ERC2981_Mutable: fee_basis_points exceeds fee denominator (10000)"):
            assert_le_felt(fee_basis_points, FEE_DENOMINATOR)
        end

        ERC2981_Mutable_token_royalty_info.write(token_id, RoyaltyInfo(receiver, fee_basis_points))
        return ()
    end

    func reset_token_royalty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ):
        with_attr error_message("ERC2981_Mutable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end
        ERC2981_Mutable_token_royalty_info.write(token_id, RoyaltyInfo(0, 0))
        return ()
    end
end
