use snforge_std::{declare, ContractClassTrait};
use cairotoken::{IAssetTokenDispatcher, IAssetTokenDispatcherTrait};
use core::starknet::contract_address::ContractAddress;
#[test]
fn call_and_invoke() {
    // First declare and deploy a contract
    // let contract = declare("NewTokenFactory").unwrap();
    let contract1 = declare("AssetToken").unwrap();
    let mut constTokenArgs = ArrayTrait::new();

    // let tokenName:felt252 = "abc";
    // let tokenSymbol:felt252 = "aaaa";
    let token_name: ByteArray = "abc"; // "abc" as byte array
    let token_symbol: ByteArray = "bbc"; // "ppp" as byte array
    let fixed_supply: u256 = 2300000;
    let default_admin = 2355298794782619854613708795067928320499387303824942644291232020925947704010;
    let minter = 2355298794782619854613708795067928320499387303824942644291232020925947704010;
    let agent = 2355298794782619854613708795067928320499387303824942644291232020925947704010;

    
    token_name.serialize(ref constTokenArgs);
    token_symbol.serialize(ref constTokenArgs);
    // owner.serialize(ref constTokenArgs);
    default_admin.serialize(ref constTokenArgs);
    fixed_supply.serialize(ref constTokenArgs);
    minter.serialize(ref constTokenArgs);
    agent.serialize(ref constTokenArgs);


    let (contract_addressToken, _) = contract1.deploy(@constTokenArgs).unwrap();
    println!("{:?}",contract_addressToken);

    // let mut constTokenArgs = ArrayTrait::new();
    // Alternatively we could use `deploy_syscall` here
    let owner = 2355298794782619854613708795067928320499387303824942644291232020925947704010;
    // let callHash:felt252 = contract1.into();

    // owner.serialize(ref constArgs);
    // callHash.serialize(ref constArgs);
   

    // let (contract_address, _) = contract.deploy(@constArgs).unwrap();

    //   println!("{:?}",contract_address);
    //   println!("{:?}",contract_address);

    // Create a Dispatcher object that will allow interacting with the deployed contract
    // let dispatcher = ITokenFactoryDispatcher { contract_address };
    // let (contract_address, _) = contract1.deploy(@constTokenArgs).unwrap();
    // let dispatcherToken = ICairoTokenDispatcher { contract_address };

    // let mut freezeconstTokenArgs = ArrayTrait::new();
    // "abc" as byte array
    // owner.serialize(ref freezeconstTokenArgs);
    // let freeze: bool = true; // "ppp" as byte array
    // three.serialize(ref freezeconstTokenArgs);
    // // Call a view function of the contract
    // let _balance = dispatcher.create_token_at(979899,112112112,49504848);
    // let balance = dispatcher.create_token_at(token_name,token_symbol,three);
    // let _balance = dispatcherToken.freeze(owner.try_into().unwrap());
    // let _mint = dispatcherToken.mint(owner.try_into().unwrap(), 2300);
    // let _balance = dispatcherToken.transfer(owner.try_into().unwrap(),owner.try_into().unwrap());

    // let state = dispatcherToken.isAccountFreezed(owner.try_into().unwrap());
// println!("{:?}",state);
// assert(balance == 0, 'balance == 0');

    // // Call a function of the contract
// // Here we mutate the state of the storage
// dispatcher.increase_balance(100);

    // // Check that transaction took effect
// let balance = dispatcher.get_balance();
// assert(balance == 100, 'balance == 100');
}
