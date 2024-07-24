import {
  RpcProvider,
  Account,
  Contract,
} from "starknet";

async function main() {
  // Configure provider and account

  const provider = new RpcProvider({
    nodeUrl: "https://free-rpc.nethermind.io/sepolia-juno/v0_6",
  });

  const privateKey =
    "0x0358ad2505ca68e5196a00151e97824cdea7a881922605579304e94b7d080902";
  const accountAddress =
    "0x05350d47c35d61ba38f895fd0ae7103d53608c05d7b68f18227ebcc9c6bdf2ca";
  const ownerAddress =
    "0x05350d47c35d61ba38f895fd0ae7103d53608c05d7b68f18227ebcc9c6bdf2ca";
  const tokenClassHash =
    "0x052e383ddb6c70b442bf37ec2951645c20776479ba458e301a0abfad66d10d8b";

  // Create a new account instance
  const account = new Account(provider, accountAddress, privateKey);

  //   const compiledTestSierra = json.parse(
  //     fs.readFileSync('src/TokenFactory.cairo').toString('ascii')
  //   );
  //   const compiledClassHash = json.parse(
  //     fs.readFileSync('target/dev/cairotoken_TokenFactory.contract_class.json').toString('ascii')
  //   );
  //   const deployResponse = await account.declareAndDeploy({
  //     contract: 'target/dev/cairotoken_TokenFactory.contract_class.json',
  //     compiledClassHash:compiledClassHash
  //   });

  //   // Connect the new contract instance:
  //   const myTestContract = new Contract(
  //     compiledTestSierra.abi,
  //     deployResponse.deploy.contract_address,
  //     provider
  //   );

  const testClassHash =
    "0x07e54eb07a8f8f0956e5f3e30c099cd870e7a9534fb3e4a53f35bb18169b75e6";
  const deployResponse = await account.deployContract({
    constructorCalldata: [ownerAddress],
    classHash: testClassHash,
  });
  //   const deployResponse = await account.deploy({
  //     constructorCalldata: [ownerAddress, tokenClassHash],
  //     classHash: testClassHash,
  //   });
  await provider.waitForTransaction(deployResponse.transaction_hash);
  console.log("deployResponse", deployResponse);
  // read abi of Test contract
  const { abi: testAbi } = await provider.getClassByHash(testClassHash);
  if (testAbi === undefined) {
    throw new Error("no abi.");
  }

  // Connect the new contract instance:
  const myTestContract = new Contract(
    testAbi,
    deployResponse.contract_address,
    provider
  );
  console.log("✅ Test Contract connected at =", myTestContract.address);

  //   console.log('Test Contract Class Hash =', deployResponse.declare.class_hash);
  //   console.log('✅ Test Contract connected at =', myTestContract.address);
}

// Run the deployment script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
