import { expect } from "chai";
import { starknet, config } from "hardhat";
import {
  toUint256WithFelts,
  tryCatch,
  shouldFail,
  fromUint256WithFelts,
  strToFeltArr,
  feltArrToStr,
} from "../../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { deployERC721 } from "../../../../utils/starknetDeploys";

// TODO: This test cases should be modularised once devnet is working
describe("ERC721 Test Cases", function () {
  console.log(`Using network ${config.starknet.network}`);
  this.timeout(300_000); // 5 min

  let contract: StarknetContract;
  let acc1: Account;
  let acc2: Account;
  let acc3: Account;

  before(async function () {
    acc1 = await starknet.deployAccount("OpenZeppelin");
    acc2 = await starknet.deployAccount("OpenZeppelin");
    acc3 = await starknet.deployAccount("OpenZeppelin");
    console.log("Deployed acc1 address: ", acc1.starknetContract.address);
    console.log("Deployed acc2 address: ", acc2.starknetContract.address);
    console.log("Deployed acc3 address: ", acc3.starknetContract.address);
    contract = await deployERC721(
      BigInt(acc1.starknetContract.address),
      "ERC721_Full"
    );

    // Grant contract owner minter role
    await acc1.invoke(contract, "grantRole", {
      role: starknet.shortStringToBigInt("MINTER_ROLE"),
      account: BigInt(acc1.starknetContract.address),
    });
  });

  /*
		ContractOwner: The 'owner' of the contract, defined as an account with the default admin role.
		NFTOwner: The 'owner' of a particular NFT.
	*/
  it("ContractOwner can mint NFTs to a different address", async function () {
    await tryCatch(async () => {
      const toWallet = BigInt(acc2.starknetContract.address);
      const num0 = toUint256WithFelts("0");
      const num1 = toUint256WithFelts("1");
      const num2 = toUint256WithFelts("2");
      const num3 = toUint256WithFelts("3");
      const num4 = toUint256WithFelts("4");
      const num5 = toUint256WithFelts("5");

      // acc1 (owner) attempt to mint to acc2 an NFT with tokenId 0 and expects balance to be 1
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: num0,
      });
      const balance1 = (await contract.call("balanceOf", { owner: toWallet }))
        .balance;
      expect(balance1).to.deep.equal(num1);

      // acc1 (owner) attempt to mint to acc2 an NFT with tokenId 1 and expects balance to be 2
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: num1,
      });
      const balance2 = (await contract.call("balanceOf", { owner: toWallet }))
        .balance;
      expect(balance2).to.deep.equal(num2);

      // acc1 (owner) attempt to mint to acc2 an NFT with tokenId 2 and expects balance to be 3
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: num2,
      });
      const balance3 = (await contract.call("balanceOf", { owner: toWallet }))
        .balance;
      expect(balance3).to.deep.equal(num3);

      // acc1 (owner) attempt to mint to acc2 an NFT with tokenId 3 and expects balance to be 4
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: num3,
      });
      const balance4 = (await contract.call("balanceOf", { owner: toWallet }))
        .balance;
      expect(balance4).to.deep.equal(num4);

      // acc1 (owner) attempt to mint to acc2 an NFT with tokenId 4 and expects balance to be 5
      await acc1.invoke(contract, "permissionedMint", {
        account: toWallet,
        tokenId: num4,
      });
      const balance5 = (await contract.call("balanceOf", { owner: toWallet }))
        .balance;
      expect(balance5).to.deep.equal(num5);
    });
  });

  it("Attempt to get tokenURI for a minted token without a set tokenURI or baseURI should return 0", async function () {
    await tryCatch(async () => {
      const tokenId = toUint256WithFelts("0");
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      expect(resultURIArr).to.deep.equal([]);
    });
  });

  it("ContractOwner can set reasonable size baseURI", async function () {
    await tryCatch(async () => {
      const url =
        "https://ipfs.io/ipfs/this-is-a-reasonable-sized-base-uri-set-by-the-owner/";

      // url must be converted to a felt array as that is the functions input type
      const baseTokenURI = strToFeltArr(url);
      await acc1.invoke(contract, "setBaseURI", {
        base_token_uri: baseTokenURI,
      });
      const tokenId = toUint256WithFelts("0");
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      const resultURI = feltArrToStr(resultURIArr);

      // The decoded return value of tokenURI should be equal to the baseURI ++ tokenId
      expect(resultURI).to.deep.equal(`${url}0`);
    });
  });

  it("ContractOwner can set tokenURI to override baseURI for a particular NFT ", async function () {
    await tryCatch(async () => {
      const url = "https://ipfs.io/ipfs/this-NFT-has-tokenId-set";

      // url must be converted to a felt array as that is the functions input type
      const tokenURI = strToFeltArr(url);
      const tokenId = toUint256WithFelts("1");

      // We setTokenURI for tokenId 1 as the owner (acc1) of the contract
      await acc1.invoke(contract, "setTokenURI", { tokenId, tokenURI });
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      const resultURI = feltArrToStr(resultURIArr);

      // The decoded return value of tokenURI for tokenId 1 should be equal to the tokenURI and NOT the baseURI
      expect(resultURI).to.deep.equal(`${url}`);

      // We ensure that tokenId, which did not have setTokenURI called still used baseURI
      const tokenId2 = toUint256WithFelts("2");
      const result2URIArr = (
        await contract.call("tokenURI", { tokenId: tokenId2 })
      ).tokenURI;
      const result2URI = feltArrToStr(result2URIArr);
      const baseUrl =
        "https://ipfs.io/ipfs/this-is-a-reasonable-sized-base-uri-set-by-the-owner/";

      // The decoded return value of tokenURI for tokenId 2 should be equal to baseURI ++ tokenId
      expect(result2URI).to.deep.equal(`${baseUrl}2`);
    });
  });

  it("ContractOwner can reset tokenURI, and it should revert to using the baseURI", async function () {
    await tryCatch(async () => {
      // url must be converted to a felt array as that is the functions input type
      const tokenId = toUint256WithFelts("1");

      // We setTokenURI for tokenId 1 as the owner (acc1) of the contract to empty
      await acc1.invoke(contract, "resetTokenURI", { tokenId });
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      const resultURI = feltArrToStr(resultURIArr);

      // The decoded return value of tokenURI for tokenId 1 should be equal to the baseURI ++ tokenId
      const baseUrl =
        "https://ipfs.io/ipfs/this-is-a-reasonable-sized-base-uri-set-by-the-owner/";
      expect(resultURI).to.deep.equal(`${baseUrl}1`);
    });
  });

  it("ContractOwner can set ASCII character set in baseURI", async function () {
    await tryCatch(async () => {
      const url = 'https://() !"[~^.Za1234567890AbcDseksicmab';
      const baseTokenURI = strToFeltArr(url);
      await acc1.invoke(contract, "setBaseURI", {
        base_token_uri: baseTokenURI,
      });
      const tokenId = toUint256WithFelts("0");
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      const resultURI = feltArrToStr(resultURIArr);
      expect(resultURI).to.deep.equal(`${url}0`);
    });
  });

  it("ContractOwner can set NOT ASCII character set in TokenURI, but will fail to decode", async function () {
    await tryCatch(async () => {
      const url = "भारत网络";
      const baseTokenURI = strToFeltArr(url);
      await acc1.invoke(contract, "setBaseURI", {
        base_token_uri: baseTokenURI,
      });
      const tokenId = toUint256WithFelts("0");
      const resultURIArr = (await contract.call("tokenURI", { tokenId }))
        .tokenURI;
      const resultURI = feltArrToStr(resultURIArr);
      expect(resultURI).to.not.deep.equal(`${url}0`);
    });
  });

  it("ContractOwner can set reasonable size ContractURI", async function () {
    await tryCatch(async () => {
      const url =
        "https://ipfs.io/ipfs/the-owner-is-trying-set-a-reasonable-sized-contract-uri/";
      const contractURI = strToFeltArr(url);

      // We use acc1 to invoke setContractURI which should pass as they are the contract owners
      await acc1.invoke(contract, "setContractURI", {
        contract_uri: contractURI,
      });
      const resultURIArr = (await contract.call("contractURI")).contract_uri;
      const resultURI = feltArrToStr(resultURIArr);

      // The contractURI, when decode, should be equal to the input url
      expect(resultURI).to.deep.equal(`${url}`);
    });
  });

  it("NOT_ContractOwner can NOT set ContractURI", async function () {
    await tryCatch(async () => {
      const url =
        "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu/";
      const contractURI = strToFeltArr(url);

      // We use acc2 to invoke setContractURI, which should fail as they are not the owner of the contract
      await shouldFail(
        acc2.invoke(contract, "setContractURI", { contract_uri: contractURI }),
        `AccessControl: caller is missing role 0`
      );
    });
  });

  it("NOT_ContractOwner can NOT mint an NFT", async function () {
    await tryCatch(async () => {
      const toWallet = BigInt(acc2.starknetContract.address);
      const tokenIdUint256 = toUint256WithFelts("20");

      // We use acc2 to invoke mint which does not have permission to mint, hence should fail
      await shouldFail(
        acc2.invoke(contract, "permissionedMint", {
          account: toWallet,
          tokenId: tokenIdUint256,
        }),
        `AccessControl: caller is missing role 93433465781963921833282629`
      );
    });
  });

  it("NFTOwner can `transferFrom` their NFT", async function () {
    await tryCatch(async () => {
      const fromAddress = BigInt(acc2.starknetContract.address);
      const toAddress = BigInt(acc1.starknetContract.address);
      // transfer tokenId 1
      const tokenIdUint256 = toUint256WithFelts("1");

      // expectedBalance of acc2 after transfer is balance-1
      const originalBalanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      const expectedBalanceFrom = (
        parseInt(fromUint256WithFelts(originalBalanceFrom).toString()) - 1
      ).toString();

      // expectedBalance of acc1 after transfer is balance+1
      const originalBalanceTo = (
        await contract.call("balanceOf", { owner: toAddress })
      ).balance;
      const expectedBalanceTo = (
        parseInt(fromUint256WithFelts(originalBalanceTo).toString()) + 1
      ).toString();

      // invoke transferFrom as the owner of the NFT (acc2)
      await acc2.invoke(contract, "transferFrom", {
        from_: fromAddress,
        to: toAddress,
        tokenId: tokenIdUint256,
      });

      // ensure balance of acc2 is as expected
      const balanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      expect(balanceFrom).to.deep.equal(
        toUint256WithFelts(expectedBalanceFrom)
      );

      // ensure balance of acc1 is as expected
      const balanceTo = (await contract.call("balanceOf", { owner: toAddress }))
        .balance;
      expect(balanceTo).to.deep.equal(toUint256WithFelts(expectedBalanceTo));
    });
  });

  it("NFTOwner can `approve` someone else then they can transfer their NFT", async function () {
    await tryCatch(async () => {
      const fromAddress = BigInt(acc2.starknetContract.address);
      const toAddress = BigInt(acc1.starknetContract.address);

      // expected balance of acc2 after transfer should be balance-1
      const originalBalanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      const expectedBalanceFrom = (
        parseInt(fromUint256WithFelts(originalBalanceFrom).toString()) - 1
      ).toString();

      // expected balance of acc1 after transfer should be balance+1
      const originalBalanceTo = (
        await contract.call("balanceOf", { owner: toAddress })
      ).balance;
      const expectedBalanceTo = (
        parseInt(fromUint256WithFelts(originalBalanceTo).toString()) + 1
      ).toString();

      // use tokenId 2
      const tokenIdUint256 = toUint256WithFelts("2");

      // approve acc1 as acc2 for tokenId
      await acc2.invoke(contract, "approve", {
        to: toAddress,
        tokenId: tokenIdUint256,
      });

      // get approved for token should be acc1
      const approvedForToken = (
        await contract.call("getApproved", { tokenId: tokenIdUint256 })
      ).approved;
      expect(approvedForToken).to.deep.equal(toAddress);

      // invoke transfer as acc1 who does not own the NFT but is approved
      await acc1.invoke(contract, "transferFrom", {
        from_: fromAddress,
        to: toAddress,
        tokenId: tokenIdUint256,
      });

      // ensure balance of acc2 is as expected
      const balanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      expect(balanceFrom).to.deep.equal(
        toUint256WithFelts(expectedBalanceFrom)
      );
      // ensure balance of acc1 is as expected
      const balanceTo = (await contract.call("balanceOf", { owner: toAddress }))
        .balance;
      expect(balanceTo).to.deep.equal(toUint256WithFelts(expectedBalanceTo));
    });
  });

  it("NFTOwner can `setApprovalForAll` and can also revoke approval", async function () {
    await tryCatch(async () => {
      const fromAddress = BigInt(acc2.starknetContract.address);
      const toAddress = BigInt(acc1.starknetContract.address);

      // expected balance of acc2 after transfer should be balance-2
      const originalBalanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      const expectedBalanceFrom = (
        parseInt(fromUint256WithFelts(originalBalanceFrom).toString()) - 2
      ).toString();

      // expected balance of acc1 after transfer should be balance+2
      const originalBalanceTo = (
        await contract.call("balanceOf", { owner: toAddress })
      ).balance;
      const expectedBalanceTo = (
        parseInt(fromUint256WithFelts(originalBalanceTo).toString()) + 2
      ).toString();

      // use tokenId 3 & 4 & 5
      const tokenId3 = toUint256WithFelts("3");
      const tokenId4 = toUint256WithFelts("4");
      const tokenId5 = toUint256WithFelts("4");

      // approve acc1 as acc2 for all tokens
      await acc2.invoke(contract, "setApprovalForAll", {
        operator: toAddress,
        approved: 1,
      });

      // get approved for token should be 1
      const isApproved = (
        await contract.call("isApprovedForAll", {
          owner: fromAddress,
          operator: toAddress,
        })
      ).isApproved;
      expect(isApproved).to.deep.equal(1n);

      // invoke transfer as acc1 who does not own the NFT3 but is approved for all
      await acc1.invoke(contract, "transferFrom", {
        from_: fromAddress,
        to: toAddress,
        tokenId: tokenId3,
      });

      // invoke transfer as acc1 who does not own the NFT4 but is approved for all
      await acc1.invoke(contract, "transferFrom", {
        from_: fromAddress,
        to: toAddress,
        tokenId: tokenId4,
      });

      // ensure balance of acc2 is as expected
      const balanceFrom = (
        await contract.call("balanceOf", { owner: fromAddress })
      ).balance;
      expect(balanceFrom).to.deep.equal(
        toUint256WithFelts(expectedBalanceFrom)
      );
      // ensure balance of acc1 is as expected
      const balanceTo = (await contract.call("balanceOf", { owner: toAddress }))
        .balance;
      expect(balanceTo).to.deep.equal(toUint256WithFelts(expectedBalanceTo));

      // revoke approve of acc1 as acc2 for all tokens
      await acc2.invoke(contract, "setApprovalForAll", {
        operator: toAddress,
        approved: 0,
      });

      const isApprovedAfterRevoke = (
        await contract.call("isApprovedForAll", {
          owner: fromAddress,
          operator: toAddress,
        })
      ).isApproved;
      expect(isApprovedAfterRevoke).to.deep.equal(0n);

      // attempt to transfer NFT5 after getting approval revoked
      await shouldFail(
        acc1.invoke(contract, "transferFrom", {
          from_: fromAddress,
          to: toAddress,
          tokenId: tokenId5,
        }),
        "ERC721: transfer from incorrect owner"
      );
    });
  });
});

/*
Questions:



*/
