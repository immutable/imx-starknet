# SPDX-License-Identifier: Apache 2.0
# Immutable Cairo Contracts v0.2.1

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721_Contract_Metadata:
    func contractURI() -> (contract_uri_len : felt, contract_uri : felt*):
    end

    func setContractURI(contract_uri_len : felt, contract_uri : felt*):
    end
end
