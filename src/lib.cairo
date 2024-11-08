pub use starknet::{ContractAddress, ClassHash};
#[starknet::interface]
pub trait IAssetToken<TContractState> {
    /// Update the class hash of the Counter contract to deploy when creating a new counter
    fn freeze(ref self: TContractState, user: ContractAddress);
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn isAccountFreezed(self: @TContractState, user: ContractAddress) -> bool;
}

const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
const AGENT_ROLE: felt252 = selector!("AGENT_ROLE");


#[starknet::contract]
mod AssetToken {
    use core::traits::Into;
    use core::traits::TryInto;
    use core::dict::Felt252Dict;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StoragePathEntry};
    use starknet::get_caller_address;
    use super::{ADMIN_ROLE};
    use super::{AGENT_ROLE};


    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);


    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        frozen: Map::<ContractAddress, bool>,
        // New storage for whitelist
        whitelist: Map<ContractAddress, bool>, // (Address, Country Code) -> Whitelisted
    }


    #[derive(Drop, starknet::Event)]
    struct WhitelistUser {
        user: ContractAddress,
        whitelisted: bool,
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
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        Frozen: FrozenUser,
        Whitelisted: WhitelistUser, // New event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        tokenName: ByteArray,
        tokenSymbol: ByteArray,
        default_admin: ContractAddress,
        fixed_supply: u256,
        minter: ContractAddress,
        agent: ContractAddress
    ) {
        self.erc20.initializer(tokenName, tokenSymbol);
        // AccessControl-related initialization
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(AGENT_ROLE, minter);
        self.erc20.mint(default_admin, fixed_supply);
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
        // Helper function to check whitelist status
        fn assert_whitelisted(ref self: ContractState) {
            let caller = get_caller_address();
            let is_whitelisted = self.is_whitelisted(caller);
            assert!(is_whitelisted, "User is not whitelisted");
        }

        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);

            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);

            self.pausable.unpause();
        }

        #[external(v0)]
        fn burn(ref self: ContractState, value: u256) {
            self.erc20.burn(get_caller_address(), value);
        }

        #[external(v0)]
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let caller = get_caller_address();

            assert!(self.is_whitelisted(caller), "User is not whitelisted");
            self.accesscontrol.assert_only_role(AGENT_ROLE);
            self.erc20.mint(recipient, amount);
        }
        #[external(v0)]
        fn freeze(ref self: ContractState, user: ContractAddress) {
            self.frozen.write(user, true);
            self.emit(FrozenUser { user: user, frozen: true, })
        }

        #[external(v0)]
        fn unfreeze(ref self: ContractState, user: ContractAddress) {
            self.frozen.write(user, false);
            self.emit(FrozenUser { user: user, frozen: false, })
        }

        #[external(v0)]
        fn isAccountFreezed(self: @ContractState, user: ContractAddress) -> bool {
            self.frozen.read(user)
        }
        #[external(v0)]
        fn add_to_whitelist(ref self: ContractState, user: ContractAddress) {
            self.accesscontrol.assert_only_role(AGENT_ROLE);
            self.whitelist.write(user, true);
            self.emit(WhitelistUser { user: user, whitelisted: true });
        }

        #[external(v0)]
        fn remove_from_whitelist(ref self: ContractState, user: ContractAddress) {
            self.accesscontrol.assert_only_role(AGENT_ROLE);
            self.whitelist.write(user, false);
            self.emit(WhitelistUser { user: user, whitelisted: false });
        }

        #[external(v0)]
        fn is_whitelisted(self: @ContractState, user: ContractAddress) -> bool {
            self.whitelist.read(user)
        }
    }
}
