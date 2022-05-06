# Immutable X Cairo Contracts

[`Building on StarkNet`](#building-on-starknet) is a beginner-friendly tutorial to help kick-start development of your StarkNet project.

If you wish to contribute to the repository, check out [`Contribution`](#contribution) for help with setting up the environment.

## Building on Starknet

Get started building your project on StarkNet! We will run through all the steps required to set up your development environment, import the Immutable X contracts into your first StarkNet contract, and compile and deploy.

### Setup

Set up your StarkNet project in a Python virtual environment:

```bash
# create a folder 'new-project' for your project
mkdir new-project
cd new-project

# setup and activate virtual environment
python3 -m venv env
source env/bin/activate
```

Using `nile`:

```bash
pip install cairo-nile
nile init
```

Using `npm`/`hardhat`:

```bash
npm init
npm i @shardlabs/starknet-hardhat-plugin
```

- Be sure to add the following line to the top of your `hardhat.config.ts` or `hardhat.config.js`:

```javascript
import "@shardlabs/starknet-hardhat-plugin";
// or
require("@shardlabs/starknet-hardhat-plugin");
```

### Install library

To install the Immutable X contracts via `pip`:

```bash
pip install immutablex-starknet
```

### Using a preset

In this example, we will deploy a basic ERC20 token contract using our `ERC20_Mintable_Capped` preset. This ERC20 features Ownable, Mintable, and Capped functionality, and can be used for a variety of use cases, such as a simple governance token.

Create a new file in the `contracts` folder called `MyERC20.cairo`. We import the `ERC20_Mintable_Capped` preset to use out-of-the-box, which includes all the required functions for your basic ERC20 token.

```
# contracts/MyERC20.cairo

%lang starknet

from immutablex.token.erc20.presets.ERC20_Mintable_Capped import constructor
```

You can add additional functions to your contract as required, as long the function name does not conflict with the existing ERC20 functions.

**Note**: With the current contract extensibility pattern on StarkNet, you cannot override functions as you would in Solidity. To modify ERC20 functions from the preset it is recommended to copy-paste the Cairo code from the preset and change as required.

### Compile contracts

Using `nile`:

```bash
nile compile
```

Using `hardhat`:

- Specify the location of any imported files with the `--cairo-path` flag, for example with python3.9 and a virtual environment named `env`:

```bash
npx hardhat starknet-compile --cairo-path 'env/lib/python3.9/site-packages'
```

### Deploy

When deploying contracts with constructor arguments, note that Cairo short strings (name and symbol) and addresses (owner) are passed as felts. Uint256 objects (cap) consist of two felts, so they would be represented as two separate inputs (low and high) in the input arguments.

These utility functions from [OpenZeppelin](https://github.com/OpenZeppelin/cairo-contracts/blob/main/tests/utils.py) may be helpful in converting inputs into felts when interacting with Cairo contracts in the CLI:

```python
def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)
```

Using `nile`:

```bash
nile deploy MyERC20 <name> <symbol> <decimals> <owner> <cap>
```

Using `hardhat`:

- Specify the network to deploy to with the `--starknet-network` flag (`alpha` is available by default and represents StarkNet's Alpha Testnet on Goerli):

```bash
npx hardhat starknet-deploy --starknet-network alpha --inputs "<name> <symbol> <decimals> <owner> <cap>"
```

## Contribution

If you wish to contribute to this repository, please check out our [contribution guidelines](../CONTRIBUTING.md). To set up the development environment:

### Install Python packages

Install the required packages in your active Python virtual environment from `requirements.txt`:

```
pip install -r requirements.txt
```

### Troubleshooting

#### Potential issues with M1 Macs

You will need to use Python 3.10 and Pip 3.10

To install, run:

```
brew install python@3.10
python3 -m pip install --upgrade pip # on mac
```

Then add this to ~/.zshrc

```
export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"
```

Some packages may not install properly when installing or compiling Cairo

Follow these instructions to fix this: https://github.com/OpenZeppelin/nile/issues/22#issuecomment-945179452

You may also run into issues with certain libraries. This is an example:

```
Traceback (most recent call last):
  File "/opt/homebrew/bin/starknet-compile", line 7, in <module>
    from starkware.starknet.compiler.compile import main  # noqa
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/starknet/compiler/compile.py", line 7, in <module>
    from starkware.cairo.lang.compiler.assembler import assemble
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/cairo/lang/compiler/assembler.py", line 3, in <module>
    from starkware.cairo.lang.compiler.debug_info import DebugInfo, HintLocation, InstructionLocation
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/cairo/lang/compiler/debug_info.py", line 11, in <module>
    from starkware.starkware_utils.validated_dataclass import ValidatedMarshmallowDataclass
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/starkware_utils/validated_dataclass.py", line 12, in <module>
    from starkware.starkware_utils.validated_fields import Field
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/starkware_utils/validated_fields.py", line 13, in <module>
    from starkware.starkware_utils.marshmallow_dataclass_fields import (
  File "/opt/homebrew/lib/python3.10/site-packages/starkware/starkware_utils/marshmallow_dataclass_fields.py", line 8, in <module>
    from frozendict import frozendict
  File "/opt/homebrew/lib/python3.10/site-packages/frozendict/__init__.py", line 16, in <module>
    class frozendict(collections.Mapping):
AttributeError: module 'collections' has no attribute 'Mapping'
```

To resolve this, reinstall the package with:

```
python3 -m pip install LIBRARY_NAME -U
# e.g. frozendict is the broken library
python3 -m pip install frozendict -U
```

### Install npm packages

```
npm i
```

### Set up starknet-devnet

https://github.com/Shard-Labs/starknet-devnet

```
pip install starknet-devnet
```

If it is your first time setting up your Cairo environment, install `gmp`:

```bash
# ubuntu
sudo apt install -y libgmp3-dev

# mac
brew install gmp
```

Run with Docker:

```
docker pull shardlabs/starknet-devnet
```

Run docker container on localhost. Use the `--lite-mode` flag to skip transaction and block hash computation to slightly improve devnet performance:

```
docker run -it -p 127.0.0.1:5050:5050 shardlabs/starknet-devnet --lite-mode
```

Set up `hardhat.config.ts` to use devnet running on port 5050:

```
starknet: {
  venv: "active",
  network: "devnet", // alpha for goerli testnet, or any other network defined in networks
  ...
},
networks: {
  devnet: {
    url: "http://localhost:5050"
  }
},
```

### Compile contracts and run tests

Compile (example):

```
npm run compile contracts/token/erc20/presets/ERC20_Mintable_Capped.cairo
```

Run tests - make sure `starknet-devnet` is running if tests are to be run on devnet:

```
npm test [path-to-test]
```

# Resources

- [`Official Cairo Setup Guide`](https://www.cairo-lang.org/docs/quickstart.html)
- [`@shardlabs/starknet-hardhat-plugin`](https://github.com/Shard-Labs/starknet-hardhat-plugin)
- [`@shardlabs/starknet-devnet`](https://github.com/Shard-Labs/starknet-devnet)
- [`starknet.js`](https://github.com/0xs34n/starknet.js)
