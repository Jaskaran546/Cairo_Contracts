pub use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    /// Create a new counter contract from stored arguments

    /// Create a new counter contract from the given arguments
    fn create_token_at(
        ref self: TContractState, owner: ContractAddress, fixed_supply: u256
    ) -> ContractAddress;

    /// Update the argument
    fn update_owner(ref self: TContractState, owner: ContractAddress);

    /// Update the class hash of the Counter contract to deploy when creating a new counter
    fn update_token_class_hash(ref self: TContractState, token_class_hash: ClassHash);
}

#[starknet::contract]
pub mod TokenFactory {
    use core::traits::Into;
    use core::traits::TryInto;
    use starknet::{ContractAddress, ClassHash, SyscallResultTrait, syscalls::deploy_syscall};

    #[storage]
    struct Storage {
        /// Store the constructor arguments of the contract to deploy
        owner: ContractAddress,
        /// Store the class hash of the contract to deploy
        token_class_hash: ClassHash,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, class_hash: ClassHash) {
        self.owner.write(owner);
        self.token_class_hash.write(class_hash);
    }

    #[abi(embed_v0)]
    impl Factory of super::ITokenFactory<ContractState> {
        fn create_token_at(
            ref self: ContractState, owner: ContractAddress, fixed_supply: u256
        ) -> ContractAddress {
            // Contructor arguments

            let mut constructor_calldata: Array<felt252> = array![];
            (self.token_class_hash.read(), owner, fixed_supply).serialize(ref constructor_calldata);
            // Contract deployment

            let (deployed_address, _) = deploy_syscall(
                self.token_class_hash.read(), 0, constructor_calldata.span(), false
            )
                .unwrap_syscall();

            deployed_address
        }


        fn update_owner(ref self: ContractState, owner: ContractAddress) {
            self.owner.write(owner);
        }

        fn update_token_class_hash(ref self: ContractState, token_class_hash: ClassHash) {
            self.token_class_hash.write(token_class_hash);
        }
    }
}
