# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1 (finance/IPaymentSplitter.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPaymentSplitter:
    func balance(token : felt) -> (balance : Uint256):
    end

    func payee(index : felt) -> (payee : felt):
    end

    func payeeCount() -> (payee_count : felt):
    end

    func totalShares() -> (total_shares : felt):
    end

    func shares(payee : felt) -> (shares : felt):
    end

    func totalReleased(token : felt) -> (total_released : Uint256):
    end

    func released(token : felt, payee : felt) -> (released : Uint256):
    end

    func pendingPayment(token : felt, payee : felt) -> (payment : Uint256):
    end

    func release(token : felt, payee : felt):
    end
end
