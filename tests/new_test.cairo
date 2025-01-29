use AssetToken::{IAssetTokenDispatcher, IAssetTokenDispatcherTrait};
use snforge_std::{declare, ContractClassTrait};

#[test]
fn call_and_invoke() {
    let token_name: ByteArray = "abc"; // "abc" as byte array
    let token_symbol: ByteArray = "bbc"; // "ppp" as byte array
    let fixed_supply: u256 = 2300000;
    let default_admin =
        2355298794782619854613708795067928320499387303824942644291232020925947704010;
    let controller = 2355298794782619854613708795067928320499387303824942644291232020925947704010;
    let agent = 2355298794782619854613708795067928320499387303824942644291232020925947704010;

    // First declare and deploy a contract
    let contract = declare("AssetToken").unwrap();
    let mut constTokenArgs = ArrayTrait::new();

    token_name.serialize(ref constTokenArgs);
    token_symbol.serialize(ref constTokenArgs);

    default_admin.serialize(ref constTokenArgs);
    fixed_supply.serialize(ref constTokenArgs);
    controller.serialize(ref constTokenArgs);
    agent.serialize(ref constTokenArgs);

    // Alternatively we could use `deploy_syscall` here
    let (contract_address, _) = contract.deploy(@constTokenArgs).unwrap();
    println!("{:?}", contract_address);

    // Create a Dispatcher object that will allow interacting with the deployed contract
    let dispatcher = IAssetTokenDispatcher { contract_address };
    // Call a view function of the contract
    let balance = dispatcher.is_whitelisted(agent);
    assert(balance == "1", 'balance == 0');




    // Call a function of the contract
// Here we mutate the state of the storage
// dispatcher.increase_balance(100);

    // Check that transaction took effect
// let balance = dispatcher.get_balance();
// assert(balance == 100, 'balance == 100');
}
