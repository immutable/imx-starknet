import { HardhatUserConfig } from "hardhat/types";
import "@shardlabs/starknet-hardhat-plugin";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  starknet: {
    venv: "active",
    network: "devnet", // alpha for goerli testnet, or any other network defined in networks
    wallets: {
      acc1: {
        accountName: "acc1",
        modulePath:
          "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts",
      },
      acc2: {
        accountName: "acc2",
        modulePath:
          "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts",
      },
    },
  },
  networks: {
    devnet: {
      url: "http://localhost:5000",
    },
  },
  paths: {
    sources: "./immutablex",
  },
};

export default config;
