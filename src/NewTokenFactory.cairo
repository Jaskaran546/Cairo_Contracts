pub use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    /// Create a new counter contract from stored arguments
    // fn create_token(ref self: TContractState) -> ContractAddress;

    /// Create a new counter contract from the given arguments
    fn create_token_at(
        ref self: TContractState, tokenName: ByteArray, tokenSymbol: ByteArray, fixed_supply: u256
    ) -> ContractAddress;

    /// Update the argument
    fn update_owner(ref self: TContractState, owner: ContractAddress);

    /// Update the class hash of the Counter contract to deploy when creating a new counter
    fn update_token_class_hash(ref self: TContractState, token_class_hash: ClassHash);
    fn get_token_class_hash(self: @TContractState) -> ClassHash;
}

#[starknet::contract]
pub mod NewTokenFactory {
    use core::traits::TryInto;
    use core::traits::Into;
    use starknet::{ContractAddress, ClassHash, SyscallResultTrait, syscalls::deploy_syscall};

    #[storage]
    struct Storage {
        /// Store the constructor arguments of the contract to deploy
        owner: ContractAddress,
        /// Store the class hash of the contract to deploy
        token_class_hash: ClassHash,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, token_class_hash: ClassHash) {
        self.owner.write(owner);
        self.token_class_hash.write(token_class_hash);
    }

    #[abi(embed_v0)]
    impl Factory of super::ITokenFactory<ContractState> {
        fn create_token_at(
            ref self: ContractState,
            tokenName: ByteArray,
            tokenSymbol: ByteArray,
            fixed_supply: u256
        ) -> ContractAddress {
            // Contructor arguments

            let mut constructor_calldata: Array<felt252> = array![];

            // constructor_calldata.append(owner.into());
            // constructor_calldata.append(tokenName.into());
            // constructor_calldata.append(tokenSymbol);
            // constructor_calldata.append(fixed_supply.low.into());
            // constructor_calldata.append(fixed_supply.try_into().unwrap());

            // let mut constructor_calldata = ArrayTrait::new();

            self.token_class_hash.read().serialize(ref constructor_calldata);
            tokenName.serialize(ref constructor_calldata);
            tokenSymbol.serialize(ref constructor_calldata);
            fixed_supply.serialize(ref constructor_calldata);

            // (self.token_class_hash.read(), owner, tokenName, tokenSymbol, fixed_supply)
            //     .serialize(ref constructor_calldata);

            let (deployed_address, _) = deploy_syscall(
                self.token_class_hash.read(), 0, constructor_calldata.span(), false
            )
                .unwrap_syscall();
            deployed_address
        }

        // fn create_token(ref self: ContractState) -> ContractAddress {
        //     self.create_token_at(self.owner.read())
        // }

        fn update_owner(ref self: ContractState, owner: ContractAddress) {
            self.owner.write(owner);
        }

        fn update_token_class_hash(ref self: ContractState, token_class_hash: ClassHash) {
            self.token_class_hash.write(token_class_hash);
        }

        fn get_token_class_hash(self: @ContractState) -> ClassHash {
            self.token_class_hash.read()
        }
    }
}

