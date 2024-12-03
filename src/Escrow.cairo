use starknet::{ContractAddress};

#[starknet::interface]
trait IEscrow<TContractState> {
    fn update_owner(ref self: TContractState, owner: ContractAddress);
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn set_admin_fee(ref self: TContractState, admin_fee: u256);
    fn set_admin_wallet(ref self: TContractState, admin_wallet: ContractAddress, id: felt252);
    fn get_admin_fee(self: @TContractState) -> u256;
    fn deposit(ref self: TContractState, token: ContractAddress, amount: u256, order_id: felt252);
    fn get_role(self: @TContractState, token: ContractAddress, user: ContractAddress) -> bool;
    fn settlement(ref self: TContractState, token: ContractAddress, order_id: felt252);
}

mod Errors {
    pub const NULL_AMOUNT: felt252 = 'Amount must be > 0';
    pub const USED_ORDERID: felt252 = 'Order Already Created';
    pub const NOT_ENOUGH_BALANCE: felt252 = 'Balance too low';
    pub const INVALID_TOKEN: felt252 = 'Unsupported Token';
}

#[starknet::contract]
pub mod Escrow {
    // Import the OpenZeppelin ownable component
    use crate::AssetToken::AGENT_ROLE;
    use crate::AssetToken::{IAssetTokenDispatcher, IAssetTokenDispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess
    };
    use starknet::{ContractAddress};
    use starknet::{get_caller_address, get_contract_address};

    // Declare the component for Ownable
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin_fee: u256,
        admin_wallet: ContractAddress,
        stable_coin: IERC20Dispatcher,
        pub balance_of: Map::<ContractAddress, u256>,
        order_created: Map::<felt252, u256>
    }

    #[derive(Drop, Debug, starknet::Event)]
    struct AdminFeeUpdated {
        #[key]
        admin_fee: u256,
    }

    #[derive(Drop, Debug, starknet::Event)]
    struct AdminUpdated {
        #[key]
        admin: ContractAddress,
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
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        AdminFeeUpdated: AdminFeeUpdated,
        AdminUpdated: AdminUpdated,
        Deposited: Deposited
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        stable_coin: ContractAddress, // Preserved in case it's needed
        owner: ContractAddress,
        admin_wallet: ContractAddress,
        admin_fee: u256 // Preserved in case it's needed
    ) {
        // Initialize the owner using OwnableComponent
        self.ownable.initializer(owner);
        self.admin_fee.write(admin_fee);
        self.admin_wallet.write(admin_wallet);
        self.stable_coin.write(IERC20Dispatcher { contract_address: stable_coin });
    }

    #[abi(embed_v0)]
    impl Escrow of super::IEscrow<ContractState> {
        // Use OwnableComponent's method to update the owner
        fn update_owner(ref self: ContractState, owner: ContractAddress) {
            self.ownable.assert_only_owner();
            self.ownable.transfer_ownership(owner);
        }

        fn set_admin_fee(ref self: ContractState, admin_fee: u256) {
            self.ownable.assert_only_owner();
            self.admin_fee.write(admin_fee);
            self.emit(AdminFeeUpdated { admin_fee: admin_fee });
        }

        fn set_admin_wallet(ref self: ContractState, admin_wallet: ContractAddress, id: felt252) {
            self.ownable.assert_only_owner();
            self.admin_wallet.write(admin_wallet);
            self.emit(AdminUpdated { admin: admin_wallet });
        }

        fn deposit(
            ref self: ContractState, token: ContractAddress, amount: u256, order_id: felt252
        ) {
            let user = get_caller_address(); // Get the caller address
            assert(self.get_role(token, user) == true, 'Investor not whitelisted');
            assert(amount != 0, super::Errors::NULL_AMOUNT);
            assert(self.order_created.read(order_id) == 0, 'Used orderid');

            // Update balance for user
            let current_balance = self.balance_of.read(user);
            self.balance_of.write(user, current_balance + amount);

            self.stable_coin.read().transfer_from(user, get_contract_address(), amount);

            // Track the order entry with `order_id`
            self.order_created.write(order_id, 1);
            self.emit(Deposited { user, amount, order_id });
        }

        fn settlement(ref self: ContractState, token: ContractAddress, order_id: felt252) {
            let user = get_caller_address(); // Get the caller address
            assert(self.get_role(token, user) == true, 'Investor not whitelisted');
        }

        // Getter for admin_fee
        fn get_admin_fee(self: @ContractState) -> u256 {
            return self.admin_fee.read();
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            return self.ownable.owner();
        }
        fn get_role(self: @ContractState, token: ContractAddress, user: ContractAddress) -> bool {
            let asset_token_dispatcher = IAssetTokenDispatcher { contract_address: token };
            return asset_token_dispatcher.has_role(AGENT_ROLE, user);
        }
    }
}
