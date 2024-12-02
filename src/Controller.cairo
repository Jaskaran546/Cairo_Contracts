use starknet::{ContractAddress};

#[starknet::interface]
trait IController<TContractState> {
    fn token_mint(
        ref self: TContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        action_id: felt252
    );
    fn token_burn(
        ref self: TContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        action_id: felt252
    );

    fn token_freeze(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, action_id: felt252
    );
    fn token_unfreeze(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, action_id: felt252
    );
    fn is_frozen_account(
        self: @TContractState, token: ContractAddress, user: ContractAddress
    ) -> bool;

    fn token_add_default_admin(
        ref self: TContractState,
        token: ContractAddress,
        admin: ContractAddress,
        action_id: felt252
    ); 

    fn token_add_agent(
        ref self: TContractState, token: ContractAddress, agent: ContractAddress, action_id: felt252
    );
    fn token_remove_agent(
        ref self: TContractState, token: ContractAddress, agent: ContractAddress, action_id: felt252
    );
    fn is_token_agent(
        self: @TContractState, token: ContractAddress, agent: ContractAddress
    ) -> bool;
    fn is_user_whitelisted(
        self: @TContractState, token: ContractAddress, user: ContractAddress
    ) -> bool;
    fn whitelist_user(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, action_id: felt252
    );
    fn remove_whitelisted_user(
        ref self: TContractState, token: ContractAddress, user: ContractAddress, action_id: felt252
    );
}


#[starknet::contract]
pub mod Controller {
    use starknet::{ContractAddress};
    use openzeppelin::access::ownable::OwnableComponent;
    use crate::AssetToken::{IAssetTokenDispatcher, IAssetTokenDispatcherTrait};
    // use starknet::storage::{Map};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[derive(Drop, Debug, starknet::Event)]
    struct Deposited {
        #[key]
        user: ContractAddress,
        amount: u256,
        action_id: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct AgentAdded {
        agent: ContractAddress,
        token_address: ContractAddress,
        action_id: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct AgentRemoved {
        agent: ContractAddress,
        token_address: ContractAddress,
        action_id: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct WhitelistUser {
        user: ContractAddress,
        whitelisted: bool,
        action_id: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct FrozenUser {
        user: ContractAddress,
        frozen: bool,
        action_id: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct Minted {
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        action_id: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct Burned {
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
        action_id: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct DefaultAdminAdded {
        token: ContractAddress,
        admin: ContractAddress,
        action_id: felt252
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Deposited: Deposited,
        Frozen: FrozenUser,
        Whitelisted: WhitelistUser, // New event
        AgentAdded: AgentAdded,
        AgentRemoved: AgentRemoved,
        Minted: Minted,
        Burned: Burned,
        DefaultAdminAdded: DefaultAdminAdded
    }
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Initialize the owner using OwnableComponent
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl Controller of super::IController<ContractState> {
        //-------------------------------TOKEN FUNCTIONS-------------------------------------

        fn token_mint(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.mint(recipient, amount);
            self
                .emit(
                    Minted {
                        token: token, recipient: recipient, amount: amount, action_id: action_id
                    }
                );
        }

        fn token_burn(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.burn(recipient, amount);
            self
                .emit(
                    Burned {
                        token: token, recipient: recipient, amount: amount, action_id: action_id
                    }
                );
        }
        fn token_freeze(
            ref self: ContractState,
            token: ContractAddress,
            user: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.freeze(user);
            self.emit(FrozenUser { user: user, frozen: true, action_id: action_id })
        }

        fn token_unfreeze(
            ref self: ContractState,
            token: ContractAddress,
            user: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.unfreeze(user);
            self.emit(FrozenUser { user: user, frozen: false, action_id: action_id })
        }

        fn is_frozen_account(
            self: @ContractState, token: ContractAddress, user: ContractAddress
        ) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.isAccountFreezed(user);
        }


        //------------------------------AGENT FUNCTIONS-------------------------------------

        fn token_add_agent(
            ref self: ContractState,
            token: ContractAddress,
            agent: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.add_token_agent(agent);
            self.emit(AgentRemoved { agent: agent, token_address: token, action_id });
        }

        fn token_remove_agent(
            ref self: ContractState,
            token: ContractAddress,
            agent: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.remove_token_agent(agent);
            self.emit(AgentRemoved { agent: agent, token_address: token, action_id });
        }

        fn is_token_agent(
            self: @ContractState, token: ContractAddress, agent: ContractAddress
        ) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.isTokenAgent(agent);
        }

        fn token_add_default_admin(
            ref self: ContractState,
            token: ContractAddress,
            admin: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.add_admin_role(admin);
            self.emit(DefaultAdminAdded { token: token, admin: admin, action_id })
        }

        //-------------------------------WHITELISTING FUNCTIONS-------------------------------------

        fn whitelist_user(
            ref self: ContractState,
            token: ContractAddress,
            user: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.add_to_whitelist(user);
            self.emit(WhitelistUser { user: user, whitelisted: true, action_id: action_id });
        }

        fn remove_whitelisted_user(
            ref self: ContractState,
            token: ContractAddress,
            user: ContractAddress,
            action_id: felt252
        ) {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            asset_token_dispatcher.remove_from_whitelist(user);
            self.emit(WhitelistUser { user: user, whitelisted: false, action_id: action_id });
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
