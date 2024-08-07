// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.14.0
pub use starknet::{ContractAddress, ClassHash};
// #[starknet::interface]
// pub trait ICairoToken<TContractState> {
//     /// Update the class hash of the Counter contract to deploy when creating a new counter
//         fn freeze(ref self: TContractState, user: ContractAddress);
//         fn mint(ref self: TContractState,recipient:ContractAddress,amount:u256);
//         fn isAccountFreezed(self: @TContractState,user:ContractAddress) -> bool;

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
        ref self: ContractState,
        tokenName: ByteArray,
        tokenSymbol: ByteArray,
        owner: ContractAddress,
        fixed_supply: u256,
    ) {
        self.erc20.initializer(tokenName, tokenSymbol);
        self.ownable.initializer(owner);
        self.erc20.mint(owner, fixed_supply);
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
            // Check if sender or recipient is frozen
            let from_frozen = contract_state.isAccountFreezed(from);
            let recipient_frozen = contract_state.isAccountFreezed(recipient);
            assert!(!from_frozen, "Sender account is frozen");
            assert!(!recipient_frozen, "Recipient account is frozen");
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
        fn freeze(ref self: ContractState, user: ContractAddress) {
            self.frozen.write(user, true);
            self.emit(FrozenUser { user: user, frozen: true, })
        }

        #[external(v0)]
        fn isAccountFreezed(self: @ContractState,user:ContractAddress) -> bool {
            self.frozen.read(user)
        }
    }
}
