import { expect } from "chai";
import { starknet } from "hardhat";
import { number, stark } from "starknet";
import {
  toUint256WithFelts,
  tryCatch,
  shouldFail,
} from "../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";
import { deployERC20 } from "../../../utils/starknetDeploys";

describe("PaymentSplitter Test Cases", function () {
  this.timeout(300_000); // 5 min

  let splitter: StarknetContract;
  let ERC20: StarknetContract;
  let acc1: Account;
  let acc2: Account;

  before(async function () {
    acc1 = await starknet.deployAccount("OpenZeppelin");
    acc2 = await starknet.deployAccount("OpenZeppelin");
    console.log("Deployed acc1 address: ", acc1.starknetContract.address);
    console.log("Deployed acc2 address: ", acc2.starknetContract.address);
    ERC20 = await deployERC20(
      BigInt(acc1.starknetContract.address),
      "ERC20_Mintable_Capped"
    );
  });

  describe("Deploy", function () {
    it("Deploy with valid inputs", async function () {
      await tryCatch(async () => {
        // convert inputs to appropriate types
        const payees = [
          BigInt(acc1.starknetContract.address),
          BigInt(acc2.starknetContract.address),
        ];
        const shares = [BigInt(150), BigInt(50)];

        // Deploy the contract
        const splitterContractFactory = await starknet.getContractFactory(
          "PaymentSplitter"
        );
        // This lets us reuse the same contract over multiple tests - not good practice but redues test times
        splitter = await splitterContractFactory.deploy({ payees, shares });

        // Call getter functions
        const ts = (await splitter.call("totalShares")).total_shares;
        const p1 = (await splitter.call("payee", { index: BigInt(0) })).payee;
        const p2 = (await splitter.call("payee", { index: BigInt(1) })).payee;
        const pc = (await splitter.call("payeeCount")).payee_count;
        const s1 = (
          await splitter.call("shares", {
            payee: BigInt(acc1.starknetContract.address),
          })
        ).shares;
        const s2 = (
          await splitter.call("shares", {
            payee: BigInt(acc2.starknetContract.address),
          })
        ).shares;

        // Expect to match inputs
        expect(p1).to.deep.equal(payees[1]);
        expect(p2).to.deep.equal(payees[0]);
        expect(pc).to.deep.equal(BigInt(2));
        expect(ts).to.deep.equal(BigInt(200));
        expect(s1).to.deep.equal(BigInt(150));
        expect(s2).to.deep.equal(BigInt(50));

        // Optional decoding to original types
        console.log(
          `Deployed PaymentSplitter contract address ${splitter.address}:`
        );
        console.log("Total Payees: ", pc.toString());
        console.log("Payee1: ", number.toHex(number.toBN(p1)));
        console.log("Payee2: ", number.toHex(number.toBN(p2)));
        console.log("Total Shares: ", ts.toString());
        console.log("Payee1 shares: ", s1.toString());
        console.log("Payee2 shares: ", s2.toString());
      });
    });

    it("Should not deploy with different length payees and shares arrays", async function () {
      await tryCatch(async () => {
        const payees = [
          BigInt(acc1.starknetContract.address),
          BigInt(acc2.starknetContract.address),
        ];
        const shares = [BigInt(150), BigInt(50), BigInt(20)];

        const splitterContractFactory = await starknet.getContractFactory(
          "PaymentSplitter"
        );
        await shouldFail(
          splitterContractFactory.deploy({ payees, shares }),
          "PaymentSplitter: payees and shares not of equal length"
        );
      });
    });

    it("Should not deploy with 0 shares for a payee", async function () {
      await tryCatch(async () => {
        const payees = [
          BigInt(acc1.starknetContract.address),
          BigInt(acc2.starknetContract.address),
        ];
        const shares = [BigInt(150), BigInt(0)];

        const splitterContractFactory = await starknet.getContractFactory(
          "PaymentSplitter"
        );
        await shouldFail(
          splitterContractFactory.deploy({ payees, shares }),
          "PaymentSplitter: shares must be greater than zero"
        );
      });
    });

    it("Should not deploy with payee that appears twice in payees array", async function () {
      await tryCatch(async () => {
        const payees = [
          BigInt(acc1.starknetContract.address),
          BigInt(acc2.starknetContract.address),
          BigInt(acc1.starknetContract.address),
        ];
        const shares = [BigInt(150), BigInt(50), BigInt(20)];

        const splitterContractFactory = await starknet.getContractFactory(
          "PaymentSplitter"
        );
        await shouldFail(
          splitterContractFactory.deploy({ payees, shares }),
          "PaymentSplitter: payee already has shares"
        );
      });
    });

    it("Should not deploy with no payees", async function () {
      await tryCatch(async () => {
        const payees: any = [];
        const shares: any = [];

        const splitterContractFactory = await starknet.getContractFactory(
          "PaymentSplitter"
        );
        await shouldFail(
          splitterContractFactory.deploy({ payees, shares }),
          "PaymentSplitter: number of payees must be greater than zero"
        );
      });
    });
  });

  describe("Payment", function () {
    it("Payer can transfer ERC20 tokens to PaymentSplitter contract", async function () {
      await tryCatch(async () => {
        const amount = toUint256WithFelts(100);
        await acc1.invoke(ERC20, "mint", {
          to: BigInt(acc1.starknetContract.address),
          amount: toUint256WithFelts(300),
        });
        await acc1.invoke(ERC20, "transfer", {
          recipient: BigInt(splitter.address),
          amount,
        });

        let balanceFromTokenContract = (
          await ERC20.call("balanceOf", { account: BigInt(splitter.address) })
        ).balance;
        expect(balanceFromTokenContract).to.deep.equal(amount);
        let balanceFromSplitterContract = (
          await splitter.call("balance", { token: BigInt(ERC20.address) })
        ).balance;
        expect(balanceFromSplitterContract).to.deep.equal(amount);
      });
    });

    it("Payee can check their pending payment balance in the PaymentSplitter contract", async function () {
      await tryCatch(async () => {
        let payment1 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc1.starknetContract.address),
          })
        ).payment;
        expect(payment1).to.deep.equal(toUint256WithFelts(75));
        let payment2 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc2.starknetContract.address),
          })
        ).payment;
        expect(payment2).to.deep.equal(toUint256WithFelts(25));
      });
    });

    it("pendingPayment should fail if the ERC20 contract does not exist", async function () {
      const randomAddress = stark.randomAddress();
      await shouldFail(
        splitter.call("pendingPayment", {
          token: BigInt(randomAddress),
          payee: BigInt(acc1.starknetContract.address),
        }),
        `PaymentSplitter: Failed to call balanceOf on token contract`
      );
    });
  });

  describe("Release", function () {
    it("Payee with no shares cannot release any funds", async function () {
      await shouldFail(
        // arbitrary payee address with no shares
        acc1.invoke(splitter, "release", {
          token: BigInt(ERC20.address),
          payee: BigInt(stark.randomAddress()),
        }),
        "PaymentSplitter: payee has no shares"
      );
    });

    it("Payee can release their pending payment", async function () {
      await tryCatch(async () => {
        await acc1.invoke(splitter, "release", {
          token: BigInt(ERC20.address),
          payee: BigInt(acc1.starknetContract.address),
        });

        let pendingPayment = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc1.starknetContract.address),
          })
        ).payment;
        let released = (
          await splitter.call("released", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc1.starknetContract.address),
          })
        ).released;
        let totalReleased = (
          await splitter.call("totalReleased", { token: BigInt(ERC20.address) })
        ).total_released;
        let payeeBalance = (
          await ERC20.call("balanceOf", {
            account: BigInt(acc1.starknetContract.address),
          })
        ).balance;

        expect(pendingPayment).to.deep.equal(toUint256WithFelts(0));
        expect(released).to.deep.equal(toUint256WithFelts(75));
        expect(totalReleased).to.deep.equal(toUint256WithFelts(75));
        expect(payeeBalance).to.deep.equal(toUint256WithFelts(75 + 200)); // 75 released + 200 not yet transferred
      });
    });

    it("Payee with no pending payment for a given ERC20 cannot release any funds", async function () {
      await shouldFail(
        acc1.invoke(splitter, "release", {
          token: BigInt(ERC20.address),
          payee: BigInt(acc1.starknetContract.address),
        }),
        "PaymentSplitter: payee is not due any payment"
      );
    });

    it("Payee pending payment is calculated correctly after receiving more funds", async function () {
      await tryCatch(async () => {
        await acc1.invoke(ERC20, "transfer", {
          recipient: BigInt(splitter.address),
          amount: toUint256WithFelts(100),
        });

        let payment1 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc1.starknetContract.address),
          })
        ).payment;
        expect(payment1).to.deep.equal(toUint256WithFelts(0 + 75)); // 0 after releasing previous payment + 75 from new payment
        let payment2 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc2.starknetContract.address),
          })
        ).payment;
        expect(payment2).to.deep.equal(toUint256WithFelts(25 + 25)); // 25 from previous payment unreleased + 25 from new payment
      });
    });

    it("Pending payment correctly rounds down with fee splits that are not exactly divisible", async function () {
      await tryCatch(async () => {
        await acc1.invoke(ERC20, "transfer", {
          recipient: BigInt(splitter.address),
          amount: toUint256WithFelts(15),
        });

        let payment1 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc1.starknetContract.address),
          })
        ).payment;
        expect(payment1).to.deep.equal(toUint256WithFelts(75 + 11)); // 75 from previous test + [(15 * (150/200 shares)) = 11.25 = 11 rounded down]
        let payment2 = (
          await splitter.call("pendingPayment", {
            token: BigInt(ERC20.address),
            payee: BigInt(acc2.starknetContract.address),
          })
        ).payment;
        expect(payment2).to.deep.equal(toUint256WithFelts(50 + 3)); // 50 from previous test + [(15 * (50/200 shares)) = 3.75 = 3 rounded down]
      });
    });
  });
});
