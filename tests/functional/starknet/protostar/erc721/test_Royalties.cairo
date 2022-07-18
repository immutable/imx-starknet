%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from immutablex.starknet.token.erc721.interfaces.IERC721 import IERC721
from immutablex.starknet.access.IAccessControl import IAccessControl
from immutablex.starknet.bridge.interfaces.IERC721_Bridgeable import IERC721_Bridgeable
from immutablex.starknet.auxiliary.erc2981.interfaces.IERC2981_Unidirectional import (
    IERC2981_Unidirectional,
)
from tests.utils.test_constants import TRUE, FALSE

const NAME = 'Rezs Raging Rhinos'
const SYMBOL = 'REZ'
const OWNER = 123456
const ROYALTY_RECIPIENT = 567890
const ROYALTY_FEE_BASIS_POINTS = 2000  # 20% default royalty

@view
func __setup__():
    %{
        context.contract_address = deploy_contract("./immutablex/starknet/token/erc721/presets/ERC721_Full.cairo", 
            [
                ids.NAME, ids.SYMBOL, ids.OWNER, ids.ROYALTY_RECIPIENT, ids.ROYALTY_FEE_BASIS_POINTS
            ]
        ).contract_address
    %}
    return ()
end

@view
func test_get_default_royalty{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    let (receiver, feeBasisPoints) = IERC2981_Unidirectional.getDefaultRoyalty(contract_address)
    assert ROYALTY_RECIPIENT = receiver
    assert ROYALTY_FEE_BASIS_POINTS = feeBasisPoints
    return ()
end

@view
func test_non_admin_cannot_set_royalty_details{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let account = 123
    let fee_basis_points = 1900  # 19%

    %{ stop_prank_callable = start_prank(ids.account, context.contract_address) %}

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    IERC2981_Unidirectional.setDefaultRoyalty(contract_address, account, fee_basis_points)

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), account, fee_basis_points
    )

    %{ stop_prank_callable() %}
    return ()
end

@view
func test_can_set_default_royalty_lower_than_current_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let fee_basis_points = 1999  # 19.99%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setDefaultRoyalty(contract_address, ROYALTY_RECIPIENT, fee_basis_points)
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert ROYALTY_RECIPIENT = receiver
    assert Uint256(1999, 0) = royaltyAmount  # 19.99% of 10,000
    return ()
end

@view
func test_can_change_royalty_recipient_for_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let new_receiver = 123

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setDefaultRoyalty(
        contract_address, new_receiver, ROYALTY_FEE_BASIS_POINTS
    )
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert new_receiver = receiver
    assert Uint256(2000, 0) = royaltyAmount
    return ()
end

@view
func test_can_reset_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.resetDefaultRoyalty(contract_address)
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert 0 = receiver
    assert Uint256(0, 0) = royaltyAmount
    return ()
end

@view
func test_cannot_increase_royalty_percentage_after_resetting_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.resetDefaultRoyalty(contract_address)

    let fee_basis_points = 1
    %{ expect_revert(error_message="ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points") %}
    IERC2981_Unidirectional.setDefaultRoyalty(contract_address, ROYALTY_RECIPIENT, fee_basis_points)
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_can_set_a_token_specific_royalty_lower_than_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let input_receiver = 123
    let fee_basis_points = 1500  # 15%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert input_receiver = receiver
    assert Uint256(1500, 0) = royaltyAmount  # 15% of 10,000
    return ()
end

@view
func test_can_set_a_token_specific_royalty_equal_to_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let input_receiver = 123
    let fee_basis_points = 2000  # 20%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert input_receiver = receiver
    assert Uint256(2000, 0) = royaltyAmount  # 20% of 10,000
    return ()
end

@view
func test_can_change_royalty_recipient_for_token_specific_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let input_receiver_1 = 123
    let input_receiver_2 = 456
    let fee_basis_points = 1800  # 18%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver_1, fee_basis_points
    )
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver_2, fee_basis_points
    )
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert input_receiver_2 = receiver
    assert Uint256(1800, 0) = royaltyAmount  # 18% of 10,000
    return ()
end

@view
func test_cannot_set_a_token_specific_royalty_higher_than_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let input_receiver = 123
    let fee_basis_points = 2001  # 20.01%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    %{ expect_revert(error_message="ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points") %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_cannot_set_a_token_specific_royalty_higher_than_existing_token_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    let input_receiver = 123
    let fee_basis_points = 1500  # 15%
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )

    let input_receiver = 123
    let fee_basis_points = 1550  # 15.5%
    %{ expect_revert(error_message="ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points") %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_cannot_set_a_token_specific_royalty_for_nonexistent_token{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}

    let input_receiver = 123
    let fee_basis_points = 2100  # 21%

    %{ expect_revert(error_message="token ID does not exist") %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    %{ stop_prank_callable() %}
    return ()
end

@view
func test_can_reset_token_specific_royalty_to_use_default_royalty{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let input_receiver = 123
    let fee_basis_points = 1500  # 15%

    %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
    IERC2981_Unidirectional.setTokenRoyalty(
        contract_address, Uint256(1, 0), input_receiver, fee_basis_points
    )
    IERC2981_Unidirectional.resetTokenRoyalty(contract_address, Uint256(1, 0))
    %{ stop_prank_callable() %}

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(10000, 0)
    )
    assert ROYALTY_RECIPIENT = receiver
    assert Uint256(2000, 0) = royaltyAmount  # 20% of 10,000
    return ()
end

# EIP-2981 states that implementers may choose round down or up to nearest integer
# This implementation (currently) always rounds down
@view
func test_get_royalty_info_should_round_down_when_not_exactly_divisible{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(123, 0)
    )
    assert ROYALTY_RECIPIENT = receiver
    assert Uint256(24, 0) = royaltyAmount  # 20% of 123 = 24.6 = 24 rounded down
    return ()
end

@view
func test_get_royalty_info_can_handle_large_sale_prices{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    local contract_address
    %{ ids.contract_address = context.contract_address %}
    test_utils.mint_token(contract_address, OWNER, Uint256(1, 0))

    let (receiver, royaltyAmount) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(1000000000, 1000000000)
    )
    assert ROYALTY_RECIPIENT = receiver
    assert Uint256(200000000, 200000000) = royaltyAmount
    return ()
end

@view
func test_revert_get_royalty_info_for_nonexistent_tokens{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}():
    tempvar contract_address
    %{ ids.contract_address = context.contract_address %}

    %{ expect_revert(error_message="token ID does not exist") %}
    let (receiver, feeBasisPoints) = IERC2981_Unidirectional.royaltyInfo(
        contract_address, Uint256(1, 0), Uint256(100, 0)
    )
    return ()
end

namespace test_utils:
    func mint_token{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        contract_address : felt, to : felt, token_id : Uint256
    ):
        %{ stop_prank_callable = start_prank(ids.OWNER, context.contract_address) %}
        IAccessControl.grantRole(contract_address, 'MINTER_ROLE', OWNER)
        IERC721_Bridgeable.permissionedMint(contract_address, to, token_id)
        %{ stop_prank_callable() %}
        return ()
    end
end
