pub use starknet::{ContractAddress, ClassHash};


#[starknet::contract]
pub mod Escrow {
    use core::traits::Into;
    use starknet::{ContractAddress, ClassHash, SyscallResultTrait, syscalls::deploy_syscall};
    use starknet::Array;
    use openzeppelin::access::ownable::OwnableComponent;


    #[storage]
    struct Storage {
        owner: ContractAddress,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        _stable_coin: Array<ContractAddress>,
        owner: ContractAddress,
        admin_fee: u256
    ) {
        self.owner.write(owner);
        self.token_class_hash.write(token_class_hash);
    }


    fn update_owner(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }
}

