import { expect } from "chai";
import { starknet, config } from "hardhat";
import {
  toUint256WithFelts,
  tryCatch,
  shouldFail,
} from "../../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { deployERC721 } from "../../../../utils/starknetDeploys";

describe("Bridgeable Test Cases", function () {
  console.log(`Using network ${config.starknet.network}`);
  this.timeout(300_000); // 5 min

  let contract: StarknetContract;
  let acc1: Account;
  let mockBridge: Account;

  before(async function () {
    acc1 = await starknet.deployAccount("OpenZeppelin");
    mockBridge = await starknet.deployAccount("OpenZeppelin");
    console.log("Deployed acc1 address: ", acc1.starknetContract.address);
    console.log(
      "Deployed mockBridge address: ",
      mockBridge.starknetContract.address
    );
    contract = await deployERC721(
      BigInt(acc1.starknetContract.address),
      "ERC721_Full"
    );
  });

  /*
		ContractOwner: The 'owner' of the contract, defined as an account with the default admin role.
		NFTOwner: The 'owner' of a particular NFT.
	*/
  it("ContractOwner can add an account to the minter and burner role", async function () {
    await tryCatch(async () => {
      const account = BigInt(mockBridge.starknetContract.address);

      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("MINTER_ROLE"),
            account,
          })
        ).res
      ).to.equal(BigInt(0));
      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("BURNER_ROLE"),
            account,
          })
        ).res
      ).to.equal(BigInt(0));

      await acc1.invoke(contract, "grantRole", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account,
      });
      await acc1.invoke(contract, "grantRole", {
        role: starknet.shortStringToBigInt("BURNER_ROLE"),
        account,
      });

      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("MINTER_ROLE"),
            account,
          })
        ).res
      ).to.equal(BigInt(1));
      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("BURNER_ROLE"),
            account,
          })
        ).res
      ).to.equal(BigInt(1));
    });
  });

  it("Non-ContractOwner cannot grant roles to accounts", async function () {
    await tryCatch(async () => {
      const account = BigInt(acc1.starknetContract.address);
      await shouldFail(
        mockBridge.invoke(contract, "grantRole", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account,
        }),
        `AccessControl: caller is missing role 0`
      );
    });
  });

  it("Minter role member can call permissionedMint", async function () {
    await tryCatch(async () => {
      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("MINTER_ROLE"),
            account: BigInt(mockBridge.starknetContract.address),
          })
        ).res
      ).to.equal(BigInt(1));

      await mockBridge.invoke(contract, "permissionedMint", {
        account: BigInt(acc1.starknetContract.address),
        tokenId: toUint256WithFelts(1),
      });

      expect(
        (await contract.call("ownerOf", { tokenId: toUint256WithFelts(1) }))
          .owner
      ).to.equal(BigInt(acc1.starknetContract.address));
    });
  });

  it("Non minter role member cannot call permissionedMint", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc1.invoke(contract, "permissionedMint", {
          account: BigInt(acc1.starknetContract.address),
          tokenId: toUint256WithFelts(2),
        }),
        `AccessControl: caller is missing role 93433465781963921833282629`
      );
    });
  });

  it("Burner role member can call permissionedBurn", async function () {
    await tryCatch(async () => {
      await mockBridge.invoke(contract, "permissionedBurn", {
        tokenId: toUint256WithFelts(1),
      });

      expect(
        (
          await contract.call("balanceOf", {
            owner: BigInt(acc1.starknetContract.address),
          })
        ).balance
      ).to.deep.equal(toUint256WithFelts(0));
    });
  });

  it("ContractOwner can revoke role for an account", async function () {
    await tryCatch(async () => {
      const account = BigInt(mockBridge.starknetContract.address);
      await acc1.invoke(contract, "revokeRole", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account,
      });

      expect(
        (
          await contract.call("hasRole", {
            role: starknet.shortStringToBigInt("MINTER_ROLE"),
            account,
          })
        ).res
      ).to.equal(BigInt(0));
      await shouldFail(
        mockBridge.invoke(contract, "permissionedMint", {
          account: BigInt(acc1.starknetContract.address),
          tokenId: toUint256WithFelts(2),
        }),
        `AccessControl: caller is missing role 93433465781963921833282629`
      );
    });
  });
});
