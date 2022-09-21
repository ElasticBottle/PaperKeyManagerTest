import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";

import "./task/deploy-upgradeable-contract";
import "./task/upgrade-contract";

dotenv.config();

// Api Keys
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
        // to enable caching for speeding up tests
        blockNumber: 15583567,
      },
    },
  },
};

export default config;
