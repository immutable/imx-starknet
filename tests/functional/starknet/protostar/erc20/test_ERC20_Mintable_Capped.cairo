%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from immutablex.starknet.token.erc20.interfaces.IERC20_Mintable_Capped import IERC20_Mintable_Capped
from tests.utils.test_constants import TRUE, FALSE

const NAME = 'CalCoin'
const SYMBOL = 'CAL'
const DECIMALS = 18
const OWNER = 123456
const CAP_LOW = 1000000
const CAP_HIGH = 0

@view
func __setup__():
    %{
        context.contract_address = deploy_contract("./immutablex/starknet/token/erc20/presets/ERC20_Mintable_Capped.cairo", 
            [
                ids.NAME, ids.SYMBOL, ids.DECIMALS, ids.OWNER, ids.CAP_LOW, ids.CAP_HIGH
            ]
        ).contract_address
    %}
    return ()
end

@view
func test_get_name{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (name) = IERC20_Mintable_Capped.name(contract_address)
    assert NAME = name
    return ()
end

@view
func test_get_symbol{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (symbol) = IERC20_Mintable_Capped.symbol(contract_address)
    assert SYMBOL = symbol
    return ()
end

@view
func test_get_decimals{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (decimals) = IERC20_Mintable_Capped.decimals(contract_address)
    assert DECIMALS = decimals
    return ()
end

@view
func test_get_owner{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (owner) = IERC20_Mintable_Capped.owner(contract_address)
    assert OWNER = owner
    return ()
end

@view
func test_get_cap{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (cap) = IERC20_Mintable_Capped.cap(contract_address)
    assert CAP_LOW = cap.low
    assert CAP_HIGH = cap.high
    return ()
end

@view
func test_owner_can_mint_tokens{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ):
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC20_Mintable_Capped.mint(contract_address, account, Uint256(100, 0))
    %{ stop_prank_callable() %}

    let (balance) = IERC20_Mintable_Capped.balanceOf(contract_address, account)
    assert 100 = balance.low
    assert 0 = balance.high
    return ()
end

@view
func test_non_owner_cannot_mint_tokens{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IERC20_Mintable_Capped.mint(contract_address, account, Uint256(100, 0))
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_cannot_mint_tokens_exceeding_maximum_supply_cap{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let account = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    # 1000001 > cap -> revert
    %{ expect_revert(error_message="Capped: cap exceeded") %}
    IERC20_Mintable_Capped.mint(contract_address, account, Uint256(1000001, 0))

    # 100000 <= cap -> success
    IERC20_Mintable_Capped.mint(contract_address, account, Uint256(1000000, 0))
    let (balance) = IERC20_Mintable_Capped.balanceOf(contract_address, account)
    assert 1000000 = balance.low
    assert 0 = balance.high

    # 1000000 + 1 > cap -> revert
    %{ expect_revert(error_message="Capped: cap exceeded") %}
    IERC20_Mintable_Capped.mint(contract_address, account, Uint256(1, 0))
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_owner_can_transfer_contract_ownership{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let new_owner = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC20_Mintable_Capped.transferOwnership(contract_address, new_owner)
    %{ stop_prank_callable() %}

    let (owner) = IERC20_Mintable_Capped.owner(contract_address)
    assert new_owner = owner
    return ()
end

@view
func test_previous_owner_cannot_transfer_contract_ownership{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let new_owner = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}

    IERC20_Mintable_Capped.transferOwnership(contract_address, new_owner)
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IERC20_Mintable_Capped.transferOwnership(contract_address, OWNER)

    %{ stop_prank_callable() %}
    return ()
end
