# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (supply/capped.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt, uint256_check
from starkware.cairo.common.bool import FALSE

from openzeppelin.security.safemath import SafeUint256

@storage_var
func _cap() -> (cap : Uint256):
end

namespace Capped:
    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        cap : Uint256
    ):
        _set_cap(cap)
        return ()
    end

    func get_cap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        cap : Uint256
    ):
        let (cap) = _cap.read()
        return (cap)
    end

    func check_cap_exceeded{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        total_supply : Uint256, amount : Uint256
    ):
        alloc_locals
        with_attr error_message("Capped: supply overflow"):
            let (new_supply : Uint256) = SafeUint256.add(total_supply, amount)
        end
        # check new_supply <= cap
        let (cap : Uint256) = _cap.read()
        let (cap_not_exceeded) = uint256_le(new_supply, cap)
        with_attr error_message("Capped: cap exceeded"):
            assert_not_zero(cap_not_exceeded)
        end
        return ()
    end

    #
    # Internal
    #

    func _set_cap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(cap : Uint256):
        uint256_check(cap)
        let (gt_zero) = uint256_lt(Uint256(0, 0), cap)  # check cap > 0
        with_attr error_message("Capped: cap must be greater than zero"):
            assert_not_zero(gt_zero)
        end
        _cap.write(cap)
        return ()
    end
end
