import { expect } from "chai";
import { BN } from "bn.js";
import { starknet } from "hardhat";
import {
  toUint256WithFelts,
  tryCatch,
  shouldFail,
} from "../../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { deployERC721 } from "../../../../utils/starknetDeploys";

describe("Royalties Test Cases", function () {
  this.timeout(300_000); // 5 min

  let contract: StarknetContract;
  let acc1: Account;
  let acc2: Account;

  before(async function () {
    acc1 = await starknet.deployAccount("OpenZeppelin");
    acc2 = await starknet.deployAccount("OpenZeppelin");
    console.log("Deployed acc1 address: ", acc1.starknetContract.address);
    console.log("Deployed acc2 address: ", acc2.starknetContract.address);
    contract = await deployERC721(
      BigInt(acc1.starknetContract.address),
      "ERC721_Full"
    );

    // Grant contract owner minter roles
    await acc1.invoke(contract, "grantRole", {
      role: starknet.shortStringToBigInt("MINTER_ROLE"),
      account: BigInt(acc1.starknetContract.address),
    });
  });

  it("royaltyInfo should fail on query for an unminted token", async function () {
    await tryCatch(async () => {
      const salePrice = toUint256WithFelts(10);

      await shouldFail(
        contract.call("royaltyInfo", {
          tokenId: toUint256WithFelts(1),
          salePrice,
        }),
        "token ID does not exist"
      );
    });
  });

  it("ContractOwner cannot set a specific token royalty for unminted tokens", async function () {
    await tryCatch(async () => {
      const royaltyRecipient = BigInt(acc1.starknetContract.address);
      const royaltyPercentage = 1000; // 10%

      // should fail to set token royalty because token is not yet minted
      await shouldFail(
        acc1.invoke(contract, "setTokenRoyalty", {
          tokenId: toUint256WithFelts(1),
          receiver: royaltyRecipient,
          feeBasisPoints: royaltyPercentage,
        }),
        `token ID does not exist`
      );
    });
  });

  it("Default royalty should be set upon initialization", async function () {
    await tryCatch(async () => {
      let defaultRoyalty = await contract.call("getDefaultRoyalty");

      // default royalty = (acc1, 20%)
      expect(defaultRoyalty.receiver).to.deep.equal(
        BigInt(acc1.starknetContract.address)
      );
      expect(defaultRoyalty.feeBasisPoints).to.deep.equal(BigInt(2000));
    });
  });

  it("ContractOwner can set a specific token royalty lower than the default royalty for a minted token", async function () {
    await tryCatch(async () => {
      // mint token id 1
      const toWallet = BigInt(acc2.starknetContract.address);
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: toUint256WithFelts(1),
      });
      const percentage = 1200; // 12%
      const salePrice = toUint256WithFelts(100);

      await acc1.invoke(contract, "setTokenRoyalty", {
        tokenId: toUint256WithFelts(1),
        receiver: toWallet,
        feeBasisPoints: percentage,
      });

      let royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice,
      });
      // token royalty for id 1 = (acc2, 12%)
      expect(royalty.receiver).to.deep.equal(toWallet);
      expect(royalty.royaltyAmount).to.deep.equal(toUint256WithFelts(12)); // 12% of 100
    });
  });

  it("ContractOwner can not set a specific token royalty lower than the default royalty but higher than the token royalty if already set", async function () {
    await tryCatch(async () => {
      const toWallet = BigInt(acc2.starknetContract.address);
      const percentage = 1300; // 13%

      await shouldFail(
        acc1.invoke(contract, "setTokenRoyalty", {
          tokenId: toUint256WithFelts(1),
          receiver: toWallet,
          feeBasisPoints: percentage,
        }),
        "ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points"
      );
    });
  });

  it("ContractOwner can not set a specific token royalty higher than the default royalty", async function () {
    await tryCatch(async () => {
      // mint token id 2
      const toWallet = BigInt(acc2.starknetContract.address);
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: toUint256WithFelts(2),
      });
      const percentage = 4750; // 47.5%

      await shouldFail(
        acc1.invoke(contract, "setTokenRoyalty", {
          tokenId: toUint256WithFelts(2),
          receiver: toWallet,
          feeBasisPoints: percentage,
        }),
        "ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points"
      );
      // token royalty for id 2 = (0, 0)
    });
  });

  it("ContractOwner can change royalty recipient without restrictions", async function () {
    await tryCatch(async () => {
      const recipient = BigInt(acc1.starknetContract.address);
      const percentage = BigInt(1200); // 12%
      const tokenId = toUint256WithFelts(1);
      await acc1.invoke(contract, "setTokenRoyalty", {
        tokenId,
        receiver: recipient,
        feeBasisPoints: percentage,
      });

      let royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice: toUint256WithFelts(10000),
      });
      // token royalty for id 1 = (acc1, 12%)
      expect(royalty.receiver).to.deep.equal(recipient);
      expect(royalty.royaltyAmount).to.deep.equal(toUint256WithFelts(1200)); // 12%
    });
  });

  // EIP-2981 states that implementers may choose round down or up to nearest integer
  // This implementation (currently) always rounds down
  it("royaltyAmount should round down to nearest integer", async function () {
    await tryCatch(async () => {
      const royaltyRecipient = BigInt(acc1.starknetContract.address);
      const salePrice = toUint256WithFelts(10);

      const royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice,
      });
      expect(royalty.receiver).to.deep.equal(royaltyRecipient);
      expect(royalty.royaltyAmount).to.deep.equal(toUint256WithFelts(1)); // 12% of 10 = 1.2 -> rounds down to 1
    });
  });

  it("royaltyAmount calculation should be able to handle large salePrices", async function () {
    await tryCatch(async () => {
      const royaltyRecipient = BigInt(acc1.starknetContract.address);
      const largeNum = new BN(
        "100000000000000000000000000000000000000000000000"
      );
      const salePrice = toUint256WithFelts(largeNum);
      const expectedRoyalty = largeNum.mul(new BN(1200)).div(new BN(10000));

      const royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice,
      });
      expect(royalty.receiver).to.deep.equal(royaltyRecipient);
      expect(royalty.royaltyAmount).to.deep.equal(
        toUint256WithFelts(expectedRoyalty)
      ); // 12%
    });
  });

  it("ContractOwner can reset a token royalty to use the default royalty info", async function () {
    await tryCatch(async () => {
      const royaltyRecipient = BigInt(acc1.starknetContract.address);
      const salePrice = toUint256WithFelts(100);

      await acc1.invoke(contract, "resetTokenRoyalty", {
        tokenId: toUint256WithFelts(1),
      });

      let royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice,
      });
      // token royalty for id 1 = (0, 0)
      expect(royalty.receiver).to.deep.equal(royaltyRecipient);
      expect(royalty.royaltyAmount).to.deep.equal(toUint256WithFelts(20)); // 20% of 100
    });
  });

  it("ContractOwner can reset a default royalty", async function () {
    await tryCatch(async () => {
      const salePrice = toUint256WithFelts(100);

      await acc1.invoke(contract, "resetDefaultRoyalty");

      let royalty = await contract.call("royaltyInfo", {
        tokenId: toUint256WithFelts(1),
        salePrice,
      });
      // default royalty = (0, 0)
      expect(royalty.receiver).to.deep.equal(BigInt(0));
      expect(royalty.royaltyAmount).to.deep.equal(toUint256WithFelts(0));
    });
  });

  it("ContractOwner can no longer set any royalty after resetting both royalties", async function () {
    await tryCatch(async () => {
      const recipient = BigInt(acc2.starknetContract.address);
      const percentage = BigInt(2000); // 20%
      const tokenId = toUint256WithFelts(2);
      await shouldFail(
        acc1.invoke(contract, "setTokenRoyalty", {
          tokenId,
          receiver: recipient,
          feeBasisPoints: percentage,
        }),
        "ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points"
      );

      await shouldFail(
        acc1.invoke(contract, "setDefaultRoyalty", {
          receiver: recipient,
          feeBasisPoints: percentage,
        }),
        "ERC2981_UniDirectional_Mutable: new fee_basis_points exceeds current fee_basis_points"
      );
    });
  });
});
