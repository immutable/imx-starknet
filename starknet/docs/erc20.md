# ERC20

This is an implementation of an ERC20 preset on StarkNet, mostly based on [OpenZeppelin's Cairo implementations](https://github.com/OpenZeppelin/cairo-contracts) of the ERC20 standard. We present our recommended preset `ERC20_Mintable_Capped`, primarily designed for the Immutable X token on StarkNet but also generalizable to the wider ecosystem as a standard ERC20 token implementation with a set of extensions to facilitate many fungible token use cases.

## Contract structure

```
erc20/
├── interfaces/
│   └── IERC20_Mintable_Capped.cairo
└── presets/
    └── ERC20_Mintable_Capped.cairo
```

- `ERC20_Mintable_Capped.cairo` is the main deployable contract, which imports functions from OpenZeppelin's base ERC20 and Ownable libraries, and implements ERC20 extensions `Mintable`, `Ownable`, and `Capped`.

## Contract Interface (IERC20_Mintable_Capped)

```
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
```

### ERC20 Compatibility

As with the OpenZeppelin Cairo ERC20 implementation, this implementation makes similar tradeoffs and workarounds for the lack of EVM compatibility on StarkNet to achieve parity with the ERC20 standard:

- Cairo's `Uint256` is used to represent Solidity's `uint256`
- Accepts a felt argument for decimals in the constructor calldata with a max value of `2^8` (imitating `uint8` type)
- Use of Cairo's short strings (of type `felt`) to represent name and symbol
- Function selectors are calculated differently between Cairo and Solidity. For maximum compatibility, the Solidity calculation of function selectors is used, not the Cairo calculation.

## Usage

The `ERC20_Mintable_Capped` preset includes `Ownable`, `Mintable`, and `Capped` functionality:

- `Ownable` - a specified address has administrative privileges over restricted actions - in this case minting and transfer of ownership

- `Mintable` - (only owner) should be able to mint ERC20 tokens to a specified address

- `Capped` - an immutable maximum supply is set on contract initialization

`ERC20_Mintable_Capped` describes a fixed supply ERC20 token with a designated contract owner who has minting rights. Such a preset would be suitable for a standard governance token, for example, but less accomodating for other bespoke functionality, such as infinite supply in-game resource tokens or otherwise.

This is an example for deploying an ERC20 token using the above preset in Javascript, using [`@shardlabs/starknet-hardhat-plugin`](https://www.npmjs.com/package/@shardlabs/starknet-hardhat-plugin) and [`starknet.js`](https://github.com/0xs34n/starknet.js).

You should first deploy an `Account` contract to use as the designated contract owner:

```typescript
// Deploy the OpenZeppelin Account contract
acc1 = await starknet.deployAccount("OpenZeppelin");
console.log("Deployed acc1 address: ", acc1.starknetContract.address);
```

Then deploy the `ERC20_Mintable_Capped` contract with chosen parameters:

```typescript
import { starknet } from "hardhat";
import { StarknetContractFactory } from "hardhat/types/runtime";

const name = starknet.shortStringToBigInt("CalCoin"); // name as Cairo short string
const symbol = starknet.shortStringToBigInt("CAL"); // symbol as Cairo short string
const decimals = BigInt(18); // decimals as felt
const owner = BigInt(acc1.starknetContract.address); // owner address as felt
const cap = toUint256WithFelts("1000000"); // supply cap as Uint256 (with felts)

// Deploy the contract
const contractFactory: StarknetContractFactory =
  await starknet.getContractFactory("ERC20_Mintable_Capped");
const contract = await contractFactory.deploy({
  name,
  symbol,
  decimals,
  owner,
  cap,
});
```

Since Cairo requires Uint256's `high` and `low` fields to be felts, we use a custom `toUint256WithFelts()` function to transform `starknet.js`'s Uint256 type:

```typescript
import { uint256 } from "starknet";

export type Uint256WithFelts = {
  low: BigInt;
  high: BigInt;
};

export function toUint256WithFelts(num: number.BigNumberish): Uint256WithFelts {
  const n = uint256.bnToUint256(num);
  return {
    low: BigInt(n.low.toString()),
    high: BigInt(n.high.toString()),
  };
}
```

To mint tokens, send a mint transaction from the owner account:

```typescript
const to = BigInt(acc1.starknetContract.address); // mint recipient address as felt
const amount = toUint256WithFelts("100"); // amount of tokens to mint as Uint256 (with felts)

// Mint tokens as owner (acc1)
await acc1.invoke(contract, "mint", { to, amount });
```

## API Specification (IERC20_Mintable_Capped)

### Methods

```
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
```

#### `name`

Returns the name of the token.

Parameters: None.

Returns:

```
name: felt
```

#### `symbol`

Returns the ticker symbol of the token.

Parameters: None.

Returns:

```
symbol: felt
```

#### `decimals`

Returns the number of decimals the token uses - e.g. 8 means to divide the token amount by 100000000 to get its user representation.

Parameters: None.

Returns:

```
decimals: felt
```

#### `totalSupply`

Returns the amount of tokens in existence.

Parameters: None.

Returns:

```
totalSupply: Uint256
```

#### `balanceOf`

Returns the amount of tokens owned by `account`.

Parameters:

```
account: felt
```

Returns:

```
balance: Uint256
```

#### `allowance`

Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through `transferFrom`. This is zero by default.

This value changes when `approve` or `transferFrom` are called.

Parameters:

```
owner: felt
spender: felt
```

Returns:

```
remaining: Uint256
```

#### `owner`

Returns the address of the contract owner as a felt.

Parameters: None.

Returns:

```
owner: felt
```

#### `cap`

Returns the maximum supply cap for the token.

Parameters: None.

Returns:

```
cap: Uint256
```

#### `transfer`

Moves `amount` tokens from the caller’s account to `recipient`. It returns `1` representing a bool if it succeeds.

Emits a Transfer event.

Parameters:

```
recipient: felt
amount: Uint256
```

Returns:

```
success: felt
```

#### `transferFrom`

Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller’s allowance. It returns `1` representing a bool if it succeeds.

Emits a Transfer event.

Parameters:

```
sender: felt
recipient: felt
amount: Uint256
```

Returns:

```
success: felt
```

#### `approve`

Sets `amount` as the allowance of `spender` over the caller’s tokens. It returns `1` representing a bool if it succeeds.

Emits an Approval event.

Parameters:

```
spender: felt
amount: Uint256
```

Returns:

```
success: felt
```

#### `increaseAllowance`

Adds `added_value` to the current allowance of `spender` for the caller’s tokens. It returns `1` representing a bool if it succeeds.

Emits an Approval event.

Parameters:

```
spender: felt
added_value: Uint256
```

Returns:

```
success: felt
```

#### `decreaseAllowance`

Subtracts `subtracted_value` from the current allowance of `spender` for the caller’s tokens. Reverts if the new allowance will be less than zero. It returns `1` representing a bool if it succeeds.

Emits an Approval event.

Parameters:

```
spender: felt
subtracted_value: Uint256
```

Returns:

```
success: felt
```

#### `transferOwnership`

Transfers ownership of the contract from the current owner to `new_owner`. Only callable by the current contract owner. It returns `1` representing a bool if it succeeds.

Parameters:

```
new_owner: felt
```

Returns:

```
success: felt
```

#### `mint`

Mints `amount` tokens to the `to` address. Only callable by the contract owner. It returns `1` representing a bool if it succeeds.

Emits a Transfer event.

Parameters:

```
to: felt
amount : Uint256
```

Returns:

```
success: felt
```

### Events

```
func Transfer(from_: felt, to: felt, value: Uint256):
end

func Approval(owner: felt, spender: felt, value: Uint256):
end
```

#### `Transfer (event)`

Emitted when `value` tokens are moved from one account (`from_`) to another (`to`).

Note that `value` may be zero.

Parameters:

```
from_: felt
to: felt
value: Uint256
```

#### `Approval (event)`

Emitted when the allowance of a `spender` for an `owner` is set by a call to approve. `value` is the new allowance.

Parameters:

```
owner: felt
spender: felt
value: Uint256
```
