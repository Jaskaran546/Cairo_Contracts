import { RpcProvider, Account, Contract } from "starknet";

async function main() {
  // Configure provider and account

  // const provider = new RpcProvider({
  //   nodeUrl: "https://free-rpc.nethermind.io/sepolia-juno/v0_6",
  // });

  const provider = new RpcProvider({
    nodeUrl: "https://free-rpc.nethermind.io/sepolia-juno/v0_7",
  });

  // const provider = new RpcProvider({ nodeUrl: 'http://127.0.0.1:5050/rpc' });

  const privateKey =
    "0x0358ad2505ca68e5196a00151e97824cdea7a881922605579304e94b7d080902";
  const accountAddress =
    "0x05350d47c35d61ba38f895fd0ae7103d53608c05d7b68f18227ebcc9c6bdf2ca";
  const ownerAddress =
    "0x05350d47c35d61ba38f895fd0ae7103d53608c05d7b68f18227ebcc9c6bdf2ca";
  const tokenClassHash =
    "0x05cc1bd09fcfa628707962d0c556a56f970301ea565b9837ad0a4a03c16fda5f";

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

  const tokenFactoryHash =
    "0x01ca9cb0f5adb27ae5787ab592d95e4a08dc5e98ae4d8cdfefc28df468483c89";
  // const deployResponse = await account.deployContract({
  //   constructorCalldata: [ownerAddress,tokenClassHash],
  //   classHash: tokenFactoryHash,
  // });
  //   const deployResponse = await account.deploy({
  //     constructorCalldata: [ownerAddress, tokenClassHash],
  //     classHash: tokenFactoryHash,
  //   });
  // await provider.waitForTransaction(deployResponse.transaction_hash);
  // console.log("deployResponse", deployResponse);
  // read abi of Test contract
  const { abi: testAbi } = await provider.getClassByHash(tokenFactoryHash);
  if (testAbi === undefined) {
    throw new Error("no abi.");
  }
  let myTestContractAddress =
    "0x0687223ac0bf5a308dfb9f780a91b13a2522ece17116de641dac8d356e6572d0";
  // Connect the new contract instance:
  const myTestContract = new Contract(testAbi, myTestContractAddress, provider);
  console.log("✅ Test Contract connected at =", myTestContract.address);
  myTestContract.connect(account);

  let test = await myTestContract.get_token_class_hash();
  console.log("test", test);

  // const myCall = myTestContract.populate("create_token_at", [
  //   await provider.getClassHashAt(myTestContractAddress),
  //   "TempToken",
  //   "TempT",
  //   500000000,
  // ]);
  const byteArray = {
    len: 0,
    data: ['0x68656c6c6f'],
    pending_word: 5,
    pending_word_len: 6
};

const SymbolbyteArray = {
  len: 0,
  data: [0x5454],
  pending_word: 2,
  pending_word_len: 6



};

  const res = await myTestContract.create_token_at(
    byteArray,
    SymbolbyteArray,
    500000000
  );
  console.log("res", res);
  await provider.waitForTransaction(res.transaction_hash);

  //   console.log('Test Contract Class Hash =', deployResponse.declare.class_hash);
  //   console.log('✅ Test Contract connected at =', myTestContract.address);
}

// Run the deployment script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
