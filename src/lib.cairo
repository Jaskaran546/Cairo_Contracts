pub mod TokenFactory;
pub mod Token;
pub use starknet::{ContractAddress, ClassHash};

// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.14.0
// #[starknet::interface]
// pub trait ICairoToken<TContractState> {
//     /// Create a new counter contract from stored arguments
//     // fn create_token(ref self: TContractState) -> ContractAddress;

//     /// Create a new counter contract from the given arguments
//     fn freeze(
//         ref self: TContractState, user: ContractAddress,freeze:bool);
// }

#[starknet::contract]
mod CairoToken {
    use core::traits::Into;
    use core::traits::TryInto;
    use core::dict::Felt252Dict;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        frozen: LegacyMap::<ContractAddress, bool>
    }

    #[derive(Drop, starknet::Event)]
    struct FrozenUser {
        user: ContractAddress,
        frozen: bool,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Frozen: FrozenUser
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, tokenName: ByteArray, tokenSymbol: ByteArray, fixed_supply: u256,
    ) {
        // let tempName: ByteArray = tokenName.try_into().unwrap();
        // let tempSymbol: ByteArray = tokenSymbol.try_into().unwrap();
        self.erc20.initializer(tokenName, tokenSymbol);
        self.ownable.initializer(get_caller_address());
        self.erc20.mint(get_caller_address(), fixed_supply);
    }

    impl ERC20HooksImpl of ERC20Component::ERC20HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            let contract_state = ERC20Component::HasComponent::get_contract(@self);
            contract_state.pausable.assert_not_paused();
        }

        fn after_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {}
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        #[external(v0)]
        fn burn(ref self: ContractState, value: u256) {
            self.erc20.burn(get_caller_address(), value);
        }

        #[external(v0)]
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            self.erc20.mint(recipient, amount);
        }
        #[external(v0)]
        fn freeze(ref self: ContractState, user: ContractAddress,freeze:bool) {
            self.ownable.assert_only_owner();
            self.frozen.write(user, true);
            self.emit(FrozenUser { user: user, frozen: true, })
        }
    }
}





// #[starknet::interface]
// pub trait ITokenFactory<TContractState> {
//     /// Create a new counter contract from stored arguments
//     // fn create_token(ref self: TContractState) -> ContractAddress;

//     /// Create a new counter contract from the given arguments
//     fn create_token_at(
//         ref self: TContractState, tokenName: ByteArray, tokenSymbol: ByteArray, fixed_supply: u256
//     ) -> ContractAddress;

//     /// Update the argument
//     fn update_owner(ref self: TContractState, owner: ContractAddress);

//     /// Update the class hash of the Counter contract to deploy when creating a new counter
//     fn update_token_class_hash(ref self: TContractState, token_class_hash: ClassHash);
//     fn get_token_class_hash(self: @TContractState) -> ClassHash;
// }

// #[starknet::contract]
// pub mod NewTokenFactory {
//     use core::traits::TryInto;
//     use core::traits::Into;
//     use starknet::{ContractAddress, ClassHash, SyscallResultTrait, syscalls::deploy_syscall};

//     #[storage]
//     struct Storage {
//         /// Store the constructor arguments of the contract to deploy
//         owner: ContractAddress,
//         /// Store the class hash of the contract to deploy
//         token_class_hash: ClassHash,
//     }

//     #[constructor]
//     fn constructor(ref self: ContractState, owner: ContractAddress, token_class_hash: ClassHash) {
//         self.owner.write(owner);
//         self.token_class_hash.write(token_class_hash);
//     }

//     #[abi(embed_v0)]
//     impl Factory of super::ITokenFactory<ContractState> {
//         fn create_token_at(
//             ref self: ContractState,
//             tokenName: ByteArray,
//             tokenSymbol: ByteArray,
//             fixed_supply: u256
//         ) -> ContractAddress {
//             // Contructor arguments

//             let mut constructor_calldata: Array<felt252> = array![];
//             // constructor_calldata.append(owner.into());
//             // constructor_calldata.append(tokenName.into());
//             // constructor_calldata.append(tokenSymbol);
//             // constructor_calldata.append(fixed_supply.low.into());
//             // constructor_calldata.append(fixed_supply.try_into().unwrap());
            
//             // let mut constructor_calldata = ArrayTrait::new();
            
//             // self.token_class_hash.read().serialize(ref constructor_calldata);
//             tokenName.serialize(ref constructor_calldata);
//             tokenSymbol.serialize(ref constructor_calldata);
//             fixed_supply.serialize(ref constructor_calldata);
            
//             // (self.token_class_hash.read(), owner, tokenName, tokenSymbol, fixed_supply)
//             //     .serialize(ref constructor_calldata);
            
//             println!("herrrrrrrrrrrrrrrrr {:?}",constructor_calldata);
//             let (deployed_address, _) = deploy_syscall(
//                 self.token_class_hash.read(), 0, constructor_calldata.span(), false
//             )
//                 .unwrap_syscall();
//             deployed_address
//         }

//         // fn create_token(ref self: ContractState) -> ContractAddress {
//         //     self.create_token_at(self.owner.read())
//         // }

//         fn update_owner(ref self: ContractState, owner: ContractAddress) {
//             self.owner.write(owner);
//         }

//         fn update_token_class_hash(ref self: ContractState, token_class_hash: ClassHash) {
//             self.token_class_hash.write(token_class_hash);
//         }

//         fn get_token_class_hash(self: @ContractState) -> ClassHash {
//             self.token_class_hash.read()
//         }
//     }
// }