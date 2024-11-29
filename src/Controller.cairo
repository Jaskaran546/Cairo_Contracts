use starknet::{ContractAddress};

#[starknet::interface]
trait IController<TContractState> {
    fn token_mint(
        ref self: TContractState, token: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn token_burn(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, value: u256
    );

    fn token_freeze(ref self: TContractState, token: ContractAddress, user: ContractAddress);
    fn token_unfreeze(ref self: TContractState, token: ContractAddress, user: ContractAddress);
    fn is_frozen_account(
        self: @TContractState, token: ContractAddress, user: ContractAddress
    ) -> bool;

    fn token_add_agent(ref self: TContractState, token: ContractAddress, user: ContractAddress);
    fn token_remove_agent(ref self: TContractState, token: ContractAddress, user: ContractAddress);
    fn is_token_agent(self: @TContractState, token: ContractAddress, user: ContractAddress) -> bool;
    fn is_user_whitelisted(
        self: @TContractState, token: ContractAddress, user: ContractAddress
    ) -> bool;
    fn whitelist_user(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, salt_id: felt252
    );
    fn remove_whitelisted_user(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, salt_id: felt252
    );
}


#[starknet::contract]
pub mod Controller {
    use starknet::{ContractAddress};
    use openzeppelin::access::ownable::OwnableComponent;
    use crate::AssetToken::{IAssetTokenDispatcher, IAssetTokenDispatcherTrait};
    use starknet::storage::{Map};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin_wallet: ContractAddress,
    }

    #[derive(Drop, Debug, starknet::Event)]
    struct Deposited {
        #[key]
        user: ContractAddress,
        amount: u256,
        order_id: felt252
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Deposited: Deposited
    }
    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, admin_wallet: ContractAddress,
    ) {
        // Initialize the owner using OwnableComponent
        self.ownable.initializer(owner);
        self.admin_wallet.write(admin_wallet);
    }

    #[abi(embed_v0)]
    impl Controller of super::IController<ContractState> {
        //-------------------------------TOKEN FUNCTIONS-------------------------------------

        fn token_mint(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.mint(recipient, amount);
        }

        fn token_burn(
            ref self: ContractState, token: ContractAddress, user: ContractAddress, value: u256
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.burn(user, value);
        }
        fn token_freeze(ref self: ContractState, token: ContractAddress, user: ContractAddress) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.freeze(user);
        }

        fn token_unfreeze(ref self: ContractState, token: ContractAddress, user: ContractAddress) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.unfreeze(user);
        }

        fn is_frozen_account(
            self: @ContractState, token: ContractAddress, user: ContractAddress
        ) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.isAccountFreezed(user);
        }


        //------------------------------AGENT FUNCTIONS-------------------------------------

        fn token_add_agent(ref self: ContractState, token: ContractAddress, user: ContractAddress) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.add_token_agent(user);
        }

        fn token_remove_agent(
            ref self: ContractState, token: ContractAddress, user: ContractAddress
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.remove_token_agent(user);
        }

        fn is_token_agent(
            self: @ContractState, token: ContractAddress, user: ContractAddress
        ) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.isTokenAgent(user);
        }

        //-------------------------------WHITELISTING FUNCTIONS-------------------------------------

        fn whitelist_user(
            ref self: ContractState, token: ContractAddress, user: ContractAddress, salt_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.add_to_whitelist(user);
        }

        fn remove_whitelisted_user(
            ref self: ContractState, token: ContractAddress, user: ContractAddress, salt_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.remove_from_whitelist(user);
        }

        fn is_user_whitelisted(
            self: @ContractState, token: ContractAddress, user: ContractAddress
        ) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.is_whitelisted(user);
        }
        //-------------------------------ESCROW FUNCTIONS-------------------------------------

    }
}