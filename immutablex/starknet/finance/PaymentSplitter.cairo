# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (finance/PaymentSplitter.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.cairo.common.uint256 import Uint256, uint256_lt

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.security.safemath import SafeUint256

#
# Events
#

@event
func PaymentReleased(token : felt, to : felt, amount : Uint256):
end

#
# Storage
#

@storage_var
func _payees(index : felt) -> (payee : felt):
end

@storage_var
func _payees_len() -> (length : felt):
end

@storage_var
func _total_shares() -> (total_shares : felt):
end

@storage_var
func _total_released(token : felt) -> (total_released : Uint256):
end

@storage_var
func _shares(payee : felt) -> (shares : felt):
end

@storage_var
func _released(token : felt, payee : felt) -> (released : Uint256):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    payees_len : felt, payees : felt*, shares_len : felt, shares : felt*
):
    with_attr error_message("PaymentSplitter: payees and shares not of equal length"):
        assert payees_len = shares_len
    end
    with_attr error_message("PaymentSplitter: number of payees must be greater than zero"):
        assert_not_zero(payees_len)
    end

    _add_payees(payees_len, payees, shares_len, shares)
    _payees_len.write(payees_len)
    return ()
end

#
# Getters
#

@view
func balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token : felt) -> (
    balance : Uint256
):
    let (balance) = _get_balance(token)
    return (balance)
end

@view
func payee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(index : felt) -> (
    payee : felt
):
    let (payee) = _payees.read(index)
    return (payee)
end

@view
func payeeCount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    payee_count : felt
):
    let (payee_count) = _payees_len.read()
    return (payee_count)
end

@view
func totalShares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    total_shares : felt
):
    let (total_shares) = _total_shares.read()
    return (total_shares)
end

@view
func totalReleased{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt
) -> (total_released : Uint256):
    let (total_released) = _total_released.read(token)
    return (total_released)
end

@view
func shares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(payee : felt) -> (
    shares : felt
):
    let (shares) = _shares.read(payee)
    return (shares)
end

@view
func released{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, payee : felt
) -> (released : Uint256):
    let (released) = _released.read(token, payee)
    return (released)
end

@view
func pendingPayment{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, payee : felt
) -> (payment : Uint256):
    let (payment : Uint256) = _get_pending_payment(token, payee)
    return (payment)
end

#
# External
#

@external
func release{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, payee : felt
):
    alloc_locals
    let (payment) = _get_pending_payment(token, payee)

    with_attr error_message("PaymentSplitter: payee is not due any payment"):
        let (gt_zero) = uint256_lt(Uint256(0, 0), payment)
        assert_not_zero(gt_zero)
    end

    # Update payee released
    let (already_released : Uint256) = _released.read(token, payee)
    let (new_released : Uint256) = SafeUint256.add(payment, already_released)
    _released.write(token, payee, new_released)

    # Update total released
    let (total_released : Uint256) = _total_released.read(token)
    let (new_total_released : Uint256) = SafeUint256.add(payment, total_released)
    _total_released.write(token, new_total_released)

    # Transfer the ERC20 tokens to payee
    IERC20.transfer(token, payee, payment)
    # Emit PaymentReleased event
    PaymentReleased.emit(token, payee, payment)
    return ()
end

#
# Internals
#

func _add_payees{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    payees_len : felt, payees : felt*, shares_len : felt, shares : felt*
):
    if payees_len * shares_len == 0:
        return ()
    end

    with_attr error_message("PaymentSplitter: shares must be greater than zero"):
        assert_lt(0, [shares])
    end
    with_attr error_message("PaymentSplitter: payee already has shares"):
        let (curr_shares) = _shares.read([payees])
        assert curr_shares = 0
    end

    # add payees
    _payees.write(payees_len - 1, [payees])
    # add new shares to total shares
    let (total_shares) = _total_shares.read()
    _total_shares.write(total_shares + [shares])
    # add payee/share entries
    _shares.write([payees], [shares])

    _add_payees(payees_len - 1, payees + 1, shares_len - 1, shares + 1)
    return ()
end

func _get_pending_payment{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt, payee : felt
) -> (pending_payment : Uint256):
    alloc_locals
    let (shares) = _shares.read(payee)
    with_attr error_message("PaymentSplitter: payee has no shares"):
        assert_lt(0, shares)
    end
    let (total_shares) = _total_shares.read()

    # total tokens received by contract = current contract balance + released tokens
    let (contract_balance) = _get_balance(token)
    let (total_released : Uint256) = _total_released.read(token)
    let (total_received : Uint256) = SafeUint256.add(contract_balance, total_released)
    let (already_released : Uint256) = _released.read(token, payee)

    # calculate pending payment
    # (total_received * (shares / total_shares)) - already_released
    let (x : Uint256) = SafeUint256.mul(total_received, Uint256(shares, 0))
    let (total_owed : Uint256, _) = SafeUint256.div_rem(x, Uint256(total_shares, 0))
    let (pending_payment) = SafeUint256.sub_le(total_owed, already_released)
    return (pending_payment)
end

func _get_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token : felt
) -> (balance : Uint256):
    let (contract_address) = get_contract_address()
    with_attr error_message("PaymentSplitter: Failed to call balanceOf on token contract"):
        let (balance) = IERC20.balanceOf(token, contract_address)
    end
    return (balance)
end
