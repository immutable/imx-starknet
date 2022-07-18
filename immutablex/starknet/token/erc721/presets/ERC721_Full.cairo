# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (token/erc721/presets/ERC721_Full.cairo)

# ERC721_Full.cairo has behaviour:
# - ERC721, TokenMetadata, ContractMetadata, AccessControl, Royalty, Bridgeable

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.access.accesscontrol import AccessControl

from immutablex.starknet.token.erc721.library import ERC721
from immutablex.starknet.token.erc721_token_metadata.library import ERC721_Token_Metadata
from immutablex.starknet.token.erc721_contract_metadata.library import ERC721_Contract_Metadata
from immutablex.starknet.auxiliary.erc2981.unidirectional_mutable import (
    ERC2981_UniDirectional_Mutable,
)

#
# Constants
#

const MINTER_ROLE = 'MINTER_ROLE'
const BURNER_ROLE = 'BURNER_ROLE'
const DEFAULT_ADMIN_ROLE = 0x00

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    symbol : felt,
    owner : felt,
    default_royalty_receiver : felt,
    default_royalty_fee_basis_points : felt,
):
    ERC721.initializer(name, symbol)
    ERC721_Token_Metadata.initializer()
    ERC2981_UniDirectional_Mutable.initializer(
        default_royalty_receiver, default_royalty_fee_basis_points
    )
    AccessControl.initializer()
    AccessControl._grant_role(DEFAULT_ADMIN_ROLE, owner)
    return ()
end

#
# View (ERC165)
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

#
# View (ERC721)
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt):
    let (isApproved : felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

#
# View (contract metadata)
#

@view
func contractURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    contract_uri_len : felt, contract_uri : felt*
):
    let (contract_uri_len, contract_uri) = ERC721_Contract_Metadata.contract_uri()
    return (contract_uri_len, contract_uri)
end

#
# View (token metadata)
#

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI_len : felt, tokenURI : felt*):
    let (tokenURI_len, tokenURI) = ERC721_Token_Metadata.token_uri(tokenId)
    return (tokenURI_len, tokenURI)
end

#
# View (royalties)
#

@view
func royaltyInfo{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256, salePrice : Uint256
) -> (receiver : felt, royaltyAmount : Uint256):
    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721: token ID does not exist"):
        assert exists = TRUE
    end
    let (receiver : felt, royaltyAmount : Uint256) = ERC2981_UniDirectional_Mutable.royalty_info(
        tokenId, salePrice
    )
    return (receiver, royaltyAmount)
end

# This function should not be used to calculate the royalty amount and simply exposes royalty info for display purposes.
# Use royaltyInfo to calculate royalty fee amounts for orders as per EIP2981.
@view
func getDefaultRoyalty{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    receiver : felt, feeBasisPoints : felt
):
    let (receiver, fee_basis_points) = ERC2981_UniDirectional_Mutable.get_default_royalty()
    return (receiver, fee_basis_points)
end

#
# View (access control)
#

@view
func hasRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    role : felt, account : felt
) -> (res : felt):
    let (res) = AccessControl.has_role(role, account)
    return (res)
end

@view
func getRoleAdmin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    role : felt
) -> (role_admin : felt):
    let (role_admin) = AccessControl.get_role_admin(role)
    return (role_admin)
end

@view
func getMinterRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    return (MINTER_ROLE)
end

@view
func getBurnerRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    return (BURNER_ROLE)
end

#
# Externals (ERC721)
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256
):
    ERC721.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
):
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

#
# External (token metadata)
#

@external
func setBaseURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    base_token_uri_len : felt, base_token_uri : felt*
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC721_Token_Metadata.set_base_token_uri(base_token_uri_len, base_token_uri)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, tokenURI_len : felt, tokenURI : felt*
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC721_Token_Metadata.set_token_uri(tokenId, tokenURI_len, tokenURI)
    return ()
end

@external
func resetTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC721_Token_Metadata.reset_token_uri(tokenId)
    return ()
end

#
# External (contract metadata)
#

@external
func setContractURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    contract_uri_len : felt, contract_uri : felt*
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC721_Contract_Metadata.set_contract_uri(contract_uri_len, contract_uri)
    return ()
end

#
# External (royalties)
#

@external
func setDefaultRoyalty{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    receiver : felt, feeBasisPoints : felt
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC2981_UniDirectional_Mutable.set_default_royalty(receiver, feeBasisPoints)
    return ()
end

@external
func setTokenRoyalty{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, receiver : felt, feeBasisPoints : felt
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721: token ID does not exist"):
        assert exists = TRUE
    end
    ERC2981_UniDirectional_Mutable.set_token_royalty(tokenId, receiver, feeBasisPoints)
    return ()
end

@external
func resetDefaultRoyalty{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    ERC2981_UniDirectional_Mutable.reset_default_royalty()
    return ()
end

@external
func resetTokenRoyalty{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
):
    AccessControl.assert_only_role(DEFAULT_ADMIN_ROLE)
    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721: token ID does not exist"):
        assert exists = TRUE
    end
    ERC2981_UniDirectional_Mutable.reset_token_royalty(tokenId)
    return ()
end

#
# External (bridgeable)
#

@external
func permissionedMint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    account : felt, tokenId : Uint256
):
    AccessControl.assert_only_role(MINTER_ROLE)
    ERC721._mint(account, tokenId)
    return ()
end

@external
func permissionedBurn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256
):
    AccessControl.assert_only_role(BURNER_ROLE)
    ERC721._burn(tokenId)
    ERC2981_UniDirectional_Mutable.reset_token_royalty(tokenId)
    return ()
end

#
# External (access control)
#

@external
func grantRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    role : felt, account : felt
):
    AccessControl.grant_role(role, account)
    return ()
end

@external
func revokeRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    role : felt, account : felt
):
    AccessControl.revoke_role(role, account)
    return ()
end

@external
func renounceRole{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    role : felt, account : felt
):
    AccessControl.renounce_role(role, account)
    return ()
end
