import { expect } from "chai";
import { starknet } from "hardhat";
import { shouldFail, tryCatch } from "../../../utils/starknetUtils";
import { StarknetContract } from "hardhat/types/runtime";
import { deployTestAccessControl } from "../../../utils/starknetDeploys";
import { Account } from "@shardlabs/starknet-hardhat-plugin/dist/src/account";

describe("AccessControl Test Cases", function () {
  this.timeout(300_000); // 5 min

  let accessControl: StarknetContract;
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
    accessControl = await deployTestAccessControl(
      BigInt(acc1.starknetContract.address)
    );
    console.log("Deployed AccessControl_mock address: ", accessControl.address);
  });

  it("Default admin should be a member of the default admin role", async function () {
    await tryCatch(async () => {
      let res = (
        await accessControl.call("has_role", {
          role: BigInt(0),
          account: BigInt(acc1.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(1));
      res = (await accessControl.call("get_role_admin", { role: BigInt(0) }))
        .role_admin;
      expect(res).to.deep.equal(BigInt(0));
    });
  });

  it("Default admin can grant new roles to accounts", async function () {
    await tryCatch(async () => {
      await acc1.invoke(accessControl, "grant_role", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account: BigInt(acc2.starknetContract.address),
      });

      await acc1.invoke(accessControl, "grant_role", {
        role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
        account: BigInt(acc3.starknetContract.address),
      });

      let res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc2.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(1));
      res = (
        await accessControl.call("get_role_admin", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
        })
      ).role_admin;
      expect(res).to.deep.equal(BigInt(0));
      res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
          account: BigInt(acc3.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(1));
      res = (
        await accessControl.call("get_role_admin", {
          role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
        })
      ).role_admin;
      expect(res).to.deep.equal(BigInt(0));
    });
  });

  it("Non role admin cannot grant new role to account", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc2.invoke(accessControl, "grant_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc3.starknetContract.address),
        }),
        `AccessControl: account is missing role`
      );
    });
  });

  it("Default admin can revoke role from account", async function () {
    await tryCatch(async () => {
      await acc1.invoke(accessControl, "revoke_role", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account: BigInt(acc2.starknetContract.address),
      });

      let res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc2.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(0));
    });
  });

  it("Default admin can set role admin", async function () {
    await tryCatch(async () => {
      await acc1.invoke(accessControl, "set_role_admin", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        admin_role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
      });

      let res = (
        await accessControl.call("get_role_admin", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
        })
      ).role_admin;
      expect(res).to.deep.equal(
        starknet.shortStringToBigInt("MINTER_ADMIN_ROLE")
      );
    });
  });

  it("Non role admin cannot set role admin", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc2.invoke(accessControl, "set_role_admin", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          admin_role: starknet.shortStringToBigInt("FAKE_MINTER_ADMIN_ROLE"),
        }),
        `AccessControl: account is missing role`
      );
    });
  });

  it("Default admin cannot grant role for a role with a non-zero (defined) admin role", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc1.invoke(accessControl, "grant_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc2.starknetContract.address),
        }),
        `AccessControl: account is missing role`
      );
    });
  });

  it("Account with admin role can grant role to account", async function () {
    await tryCatch(async () => {
      await acc3.invoke(accessControl, "grant_role", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account: BigInt(acc2.starknetContract.address),
      });

      let res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc2.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(1));
    });
  });

  it("Account with admin role can revoke roles for their managed role", async function () {
    await tryCatch(async () => {
      await acc3.invoke(accessControl, "revoke_role", {
        role: starknet.shortStringToBigInt("MINTER_ROLE"),
        account: BigInt(acc2.starknetContract.address),
      });

      let res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ROLE"),
          account: BigInt(acc2.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(0));
    });
  });

  it("Account with admin role cannot revoke roles for which it is not an admin", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc3.invoke(accessControl, "revoke_role", {
          role: starknet.shortStringToBigInt("DEFAULT_ADMIN_ROLE"),
          account: BigInt(acc1.starknetContract.address),
        }),
        `AccessControl: account is missing role`
      );
    });
  });

  it("Account cannot renounce role for another account", async function () {
    await tryCatch(async () => {
      await shouldFail(
        acc1.invoke(accessControl, "renounce_role", {
          role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
          account: BigInt(acc3.starknetContract.address),
        }),
        "AccessControl: can only renounce roles for self"
      );
    });
  });

  it("Role member can renounce role", async function () {
    await tryCatch(async () => {
      await acc3.invoke(accessControl, "renounce_role", {
        role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
        account: BigInt(acc3.starknetContract.address),
      });

      let res = (
        await accessControl.call("has_role", {
          role: starknet.shortStringToBigInt("MINTER_ADMIN_ROLE"),
          account: BigInt(acc3.starknetContract.address),
        })
      ).res;
      expect(res).to.deep.equal(BigInt(0));
    });
  });
});
