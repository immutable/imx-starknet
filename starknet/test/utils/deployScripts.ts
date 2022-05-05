import { expect } from "chai";
import { starknet } from "hardhat";
import {
  StarknetContract,
  StarknetContractFactory,
} from "hardhat/types/runtime";
import { toUint256WithFelts } from "./utils";
import { number, uint256 } from "starknet";

export async function deployERC721(
  owner: BigInt,
  erc721Type: string
): Promise<StarknetContract> {
  const name = starknet.shortStringToBigInt("Rez's Raging Rhinos");
  const symbol = starknet.shortStringToBigInt("REZ");
  const default_royalty_receiver = owner;
  const default_royalty_fee_basis_points = BigInt(2000);

  // Deploy the contract

  const contractFactory: StarknetContractFactory =
    await starknet.getContractFactory(erc721Type);
  const contract = await contractFactory.deploy({
    name,
    symbol,
    owner,
    default_royalty_receiver,
    default_royalty_fee_basis_points,
  });

  // This lets us reuse the same contract over multiple tests - not good practice but redues test times
  console.log("Successfully deployed");

  // Call getter functions
  const n = (await contract.call("name")).name;
  const s = (await contract.call("symbol")).symbol;
  const o = (await contract.call("owner")).owner;
  const r = await contract.call("getDefaultRoyalty");

  // Expect to match inputs
  expect(n).to.deep.equal(name);
  expect(s).to.deep.equal(symbol);
  expect(o).to.deep.equal(owner);
  expect(r.receiver).to.deep.equal(default_royalty_receiver);
  expect(r.feeBasisPoints).to.deep.equal(default_royalty_fee_basis_points);

  console.log(`Deployed contract to ${contract.address}`);
  return contract;
}

export async function deployERC20(
  owner: BigInt,
  erc20Type: string
): Promise<StarknetContract> {
  const name = starknet.shortStringToBigInt("CalCoin");
  const symbol = starknet.shortStringToBigInt("CAL");
  const cap = toUint256WithFelts("1000000");
  const decimals = BigInt(18);

  // Deploy the contract
  const contractFactory: StarknetContractFactory =
    await starknet.getContractFactory(erc20Type);
  const contract = await contractFactory.deploy({
    name,
    symbol,
    decimals,
    owner,
    cap,
  });

  // Call getter functions
  const n = (await contract.call("name")).name;
  const s = (await contract.call("symbol")).symbol;
  const d = (await contract.call("decimals")).decimals;
  const o = (await contract.call("owner")).owner;
  const c = (await contract.call("cap")).cap;

  // Expect to match inputs
  expect(n).to.deep.equal(name);
  expect(s).to.deep.equal(symbol);
  expect(d).to.deep.equal(decimals);
  expect(o).to.deep.equal(owner);
  expect(c).to.deep.equal(cap);

  // Optional decoding to original types
  console.log(`Deployed contract to ${contract.address} with args:`);
  console.log("name: ", starknet.bigIntToShortString(n));
  console.log("symbol: ", starknet.bigIntToShortString(s));
  console.log("decimals: ", d.toString());
  console.log("owner: ", number.toHex(o.toString()));
  console.log("cap: ", uint256.uint256ToBN(c).toString());
  return contract;
}

export async function deployTestSafeMath(): Promise<StarknetContract> {
  const contractFactory: StarknetContractFactory =
    await starknet.getContractFactory("SafeMath_mock");
  const contract = await contractFactory.deploy();
  return contract;
}
