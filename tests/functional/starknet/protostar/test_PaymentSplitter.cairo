%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from immutablex.starknet.finance.IPaymentSplitter import IPaymentSplitter
from immutablex.starknet.token.erc20.interfaces.IERC20_Mintable_Capped import IERC20_Mintable_Capped
from tests.utils.test_constants import TRUE, FALSE

const PAYEE_ACCOUNT_1 = 123
const PAYEE_SHARES_1 = 150
const PAYEE_ACCOUNT_2 = 456
const PAYEE_SHARES_2 = 50
const ERC20_OWNER = 789

@view
func __setup__():
    %{
        context.splitter_contract = deploy_contract("./immutablex/starknet/finance/PaymentSplitter.cairo", 
            [
                2, ids.PAYEE_ACCOUNT_1, ids.PAYEE_ACCOUNT_2,
                2, ids.PAYEE_SHARES_1, ids.PAYEE_SHARES_2
            ]
        ).contract_address
        context.erc20_contract = deploy_contract("./immutablex/starknet/token/erc20/presets/ERC20_Mintable_Capped.cairo", 
            [
                111111, 111, 18, ids.ERC20_OWNER, 1000000, 0
            ]
        ).contract_address
    %}
    return ()
end

@view
func test_get_total_shares{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar splitter_contract
    %{ ids.splitter_contract = context.splitter_contract %}

    let (total_shares) = IPaymentSplitter.totalShares(splitter_contract)
    assert 200 = total_shares
    return ()
end

@view
func test_get_payee_by_index{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar splitter_contract
    %{ ids.splitter_contract = context.splitter_contract %}

    let (payee_0) = IPaymentSplitter.payee(splitter_contract, 0)
    assert PAYEE_ACCOUNT_2 = payee_0

    let (payee_1) = IPaymentSplitter.payee(splitter_contract, 1)
    assert PAYEE_ACCOUNT_1 = payee_1
    return ()
end

@view
func test_get_payee_count{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar splitter_contract
    %{ ids.splitter_contract = context.splitter_contract %}

    let (payee_count) = IPaymentSplitter.payeeCount(splitter_contract)
    assert 2 = payee_count
    return ()
end

@view
func test_get_shares_by_payee{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar splitter_contract
    %{ ids.splitter_contract = context.splitter_contract %}

    let (shares_0) = IPaymentSplitter.shares(splitter_contract, PAYEE_ACCOUNT_1)
    assert 150 = shares_0

    let (shares_1) = IPaymentSplitter.shares(splitter_contract, PAYEE_ACCOUNT_2)
    assert 50 = shares_1
    return ()
end

@view
func test_get_balance_by_token{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    let (balance) = IPaymentSplitter.balance(splitter_contract, erc20_contract)
    assert 100 = balance.low
    assert 0 = balance.high
    return ()
end

@view
func test_get_pending_payment_balance{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    let (pending_payment_1) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_1
    )
    assert 75 = pending_payment_1.low
    assert 0 = pending_payment_1.high
    let (pending_payment_2) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_2
    )
    assert 25 = pending_payment_2.low
    assert 0 = pending_payment_2.high
    return ()
end

@view
func test_revert_get_pending_payment_for_non_existent_token{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar splitter_contract
    %{ ids.splitter_contract = context.splitter_contract %}

    let non_existent_token = 99999

    %{ expect_revert(error_message="PaymentSplitter: Failed to call balanceOf on token contract") %}
    let (pending_payment) = IPaymentSplitter.pendingPayment(
        splitter_contract, non_existent_token, PAYEE_ACCOUNT_1
    )
    return ()
end

@view
func test_revert_get_pending_payment_for_non_payee{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    let non_payee = 888

    %{ expect_revert(error_message="PaymentSplitter: payee has no shares") %}
    let (pending_payment) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, non_payee
    )
    return ()
end

@view
func test_release_payment{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    %{ expect_events({"name": "PaymentReleased", "data": [ids.erc20_contract, ids.PAYEE_ACCOUNT_1, 75, 0]}) %}
    IPaymentSplitter.release(splitter_contract, erc20_contract, PAYEE_ACCOUNT_1)

    let (pending_payment) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_1
    )
    assert 0 = pending_payment.low
    assert 0 = pending_payment.high

    let (released) = IPaymentSplitter.released(splitter_contract, erc20_contract, PAYEE_ACCOUNT_1)
    assert 75 = released.low
    assert 0 = released.high

    let (total_released) = IPaymentSplitter.totalReleased(splitter_contract, erc20_contract)
    assert 75 = total_released.low
    assert 0 = total_released.high

    let (payee_balance) = IERC20_Mintable_Capped.balanceOf(erc20_contract, PAYEE_ACCOUNT_1)
    assert 75 = payee_balance.low
    assert 0 = payee_balance.high
    return ()
end

@view
func test_revert_release_payment_for_non_payee{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    let non_payee = 888

    %{ expect_revert(error_message="PaymentSplitter: payee has no shares") %}
    IPaymentSplitter.release(splitter_contract, erc20_contract, non_payee)
    return ()
end

@view
func test_revert_release_payment_for_no_pending_payment_amount{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    tempvar erc20_contract
    tempvar splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}

    %{ expect_revert(error_message="PaymentSplitter: payee is not due any payment") %}
    IPaymentSplitter.release(splitter_contract, erc20_contract, PAYEE_ACCOUNT_1)
    return ()
end

@view
func test_pending_payment_calculations_after_released_payment{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(100, 0))

    IPaymentSplitter.release(splitter_contract, erc20_contract, PAYEE_ACCOUNT_1)

    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(200, 0))

    let (pending_payment_1) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_1
    )
    assert 150 = pending_payment_1.low
    assert 0 = pending_payment_1.high
    let (pending_payment_2) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_2
    )
    assert 75 = pending_payment_2.low
    assert 0 = pending_payment_2.high
    return ()
end

@view
func test_pending_payment_rounds_down_for_fee_splits_that_are_not_exactly_divisble{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local erc20_contract
    local splitter_contract
    %{
        ids.erc20_contract = context.erc20_contract
        ids.splitter_contract = context.splitter_contract
    %}
    test_utils.send_payment_to_splitter(splitter_contract, erc20_contract, Uint256(15, 0))

    let (pending_payment_1) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_1
    )
    # (15 * (150/200 shares)) = 11.25 = 11 rounded down
    assert 11 = pending_payment_1.low
    assert 0 = pending_payment_1.high

    let (pending_payment_2) = IPaymentSplitter.pendingPayment(
        splitter_contract, erc20_contract, PAYEE_ACCOUNT_2
    )
    # (15 * (50/200 shares)) = 3.75 = 3 rounded down
    assert 3 = pending_payment_2.low
    assert 0 = pending_payment_2.high
    return ()
end

namespace test_utils:
    func send_payment_to_splitter{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
    }(splitter : felt, erc20 : felt, amount : Uint256):
        %{ stop_prank_callable = start_prank(ids.ERC20_OWNER, context.erc20_contract) %}
        IERC20_Mintable_Capped.mint(erc20, splitter, amount)
        %{ stop_prank_callable() %}
        return ()
    end
end
