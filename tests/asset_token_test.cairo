// # batch_mint_test.cairo

// #[cfg(test)]
// mod tests {
//     use snforge_std::*;
//     use starknet::ContractAddress;

//     #[starknet::test]
//     fn test_batch_mint() {
//         let mut test_env = TestEnv::default();

//         // Declare and deploy the AssetToken contract
//         let asset_token = test_env.declare("AssetToken").deploy(());

//         // Define test addresses and amounts
//         let recipient_1 = ContractAddress::try_from_felt(0x1).unwrap();
//         let recipient_2 = ContractAddress::try_from_felt(0x2).unwrap();
//         let amount_1 = 100u256;
//         let amount_2 = 200u256;

//         // Add an agent with minting privileges
//         let agent = ContractAddress::try_from_felt(0x3).unwrap();
//         asset_token.call("add_token_agent", (agent,));

//         // Whitelist recipients
//         asset_token.call("add_to_whitelist", (recipient_1,));
//         asset_token.call("add_to_whitelist", (recipient_2,));

//         // Perform batch mint
//         asset_token.call("batch_mint", ([recipient_1, recipient_2], [amount_1, amount_2]));

//         // Verify balances
//         let balance_1: u256 = asset_token.call("balance_of", (recipient_1,));
//         let balance_2: u256 = asset_token.call("balance_of", (recipient_2,));

//         assert_eq!(balance_1, amount_1, "Recipient 1 balance incorrect");
//         assert_eq!(balance_2, amount_2, "Recipient 2 balance incorrect");
//     }
// }
