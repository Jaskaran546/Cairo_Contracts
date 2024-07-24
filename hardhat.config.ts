import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@shardlabs/starknet-hardhat-plugin";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};
module.exports = {
  starknet: {
    // Only one of these properties can be specified.
    // cairo1BinDir: "/target/dev",
    // compilerVersion: "1.1.1",
  },
  paths: {
    starknetSources: "src",
    starknetArtifacts: "starknet-artifacts",
  },
};
export default config;
