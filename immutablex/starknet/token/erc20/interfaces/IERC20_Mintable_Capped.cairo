# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (token/erc20/interfaces/IERC20_Mintable_Capped.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC20_Mintable_Capped:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func decimals() -> (decimals : felt):
    end

    func totalSupply() -> (totalSupply : Uint256):
    end

    func balanceOf(account : felt) -> (balance : Uint256):
    end

    func allowance(owner : felt, spender : felt) -> (remaining : Uint256):
    end

    func owner() -> (owner : felt):
    end

    func cap() -> (cap : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256) -> (success : felt):
    end

    func transferFrom(sender : felt, recipient : felt, amount : Uint256) -> (success : felt):
    end

    func approve(spender : felt, amount : Uint256) -> (success : felt):
    end

    func increaseAllowance(spender : felt, added_value : Uint256) -> (success : felt):
    end

    func decreaseAllowance(spender : felt, subtracted_value : Uint256) -> (success : felt):
    end

    func transferOwnership(new_owner : felt) -> (success : felt):
    end

    func mint(to : felt, amount : Uint256) -> (success : felt):
    end
end
