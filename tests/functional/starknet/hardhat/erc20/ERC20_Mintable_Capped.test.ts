import { expect } from "chai";
import { starknet } from "hardhat";
import {
  toUint256WithFelts,
  tryCatch,
  shouldFail,
} from "../../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { deployERC20 } from "../../../../utils/starknetDeploys";

describe("ERC20_Mintable_Capped test cases", function () {
  this.timeout(300_000); // 5 min

  // This lets us reuse the same contract over multiple tests - not good practice but redues test times slightly
  let contract: StarknetContract;
  let acc1: Account;
  let acc2: Account;

  before(async function () {
    acc1 = await starknet.deployAccount("OpenZeppelin");
    acc2 = await starknet.deployAccount("OpenZeppelin");
    console.log("Deployed acc1 address: ", acc1.starknetContract.address);
    console.log("Deployed acc2 address: ", acc2.starknetContract.address);
    contract = await deployERC20(
      BigInt(acc1.starknetContract.address),
      "ERC20_Mintable_Capped"
    );
  });

  describe("Mintable", function () {
    it("As a contract owner, I should be able to mint a given amount to any user", async function () {
      await tryCatch(async () => {
        const toWallet1 = BigInt(acc1.starknetContract.address);
        const toWallet2 = BigInt(acc2.starknetContract.address);
        const amount = toUint256WithFelts("100");
        await acc1.invoke(contract, "mint", { to: toWallet1, amount: amount });
        await acc1.invoke(contract, "mint", { to: toWallet2, amount: amount });

        let balance = (await contract.call("balanceOf", { account: toWallet1 }))
          .balance;
        expect(balance).to.deep.equal(amount);
        balance = (await contract.call("balanceOf", { account: toWallet2 }))
          .balance;
        expect(balance).to.deep.equal(amount);
      });
    });

    it("As a non-contract-owner, I should be not able to mint tokens", async function () {
      await tryCatch(async () => {
        const toWallet = BigInt(acc2.starknetContract.address);
        const amount = toUint256WithFelts("100");
        await shouldFail(
          acc2.invoke(contract, "mint", { to: toWallet, amount: amount }),
          "Ownable: caller is not the owner"
        );
      });
    });
  });

  describe("Capped", function () {
    it("As a contract owner, minting should not be able to exceed the maximum supply cap", async function () {
      await tryCatch(async () => {
        const toWallet = BigInt(acc1.starknetContract.address);
        const amount = toUint256WithFelts("1000001");
        await shouldFail(
          acc1.invoke(contract, "mint", { to: toWallet, amount: amount }),
          "Capped: cap exceeded"
        );
      });
    });
  });

  describe("Ownable", function () {
    it("As a non-contract owner, I should not be able to change contract ownership", async function () {
      await tryCatch(async () => {
        const newOwner = BigInt(acc2.starknetContract.address);
        await shouldFail(
          acc2.invoke(contract, "transferOwnership", { new_owner: newOwner }),
          "Ownable: caller is not the owner"
        );
      });
    });

    it("As a contract owner, I should be able to transfer contract ownership to another user", async function () {
      await tryCatch(async () => {
        const newOwner = BigInt(acc2.starknetContract.address);
        await acc1.invoke(contract, "transferOwnership", {
          new_owner: newOwner,
        });

        const owner = (await contract.call("owner")).owner;
        expect(owner).to.deep.equal(newOwner);
      });
    });
  });
});
