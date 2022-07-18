# SPDX-License-Identifier: Apache 2.0
# Based on OpenZeppelin Contracts for Cairo v0.2.1 (utils/constants.cairo)
# Modified by Immutable v0.2.1 (utils/constants.cairo)
# - Added IERC20_RECEIVER_ID and IERC2981_ID constants

%lang starknet

#
# Numbers
#

const UINT8_MAX = 256

#
# Interface Ids
#

# NOTE: these are the solidity interface ids, and might be different if generated natively in cairo ###

# ERC165
const IERC165_ID = 0x01ffc9a7
const INVALID_ID = 0xffffffff

# Account
const IACCOUNT_ID = 0xf10dbd44

# ERC721
const IERC721_ID = 0x80ac58cd
const IERC721_RECEIVER_ID = 0x150b7a02
const IERC721_METADATA_ID = 0x5b5e139f
const IERC721_ENUMERABLE_ID = 0x780e9d63

# ERC20
const IERC20_RECEIVER_ID = 0x4fc35859

# ERC2981
const IERC2981_ID = 0x2a55205a

# AccessControl
const IACCESSCONTROL_ID = 0x7965db0b
