// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GymLoyaltyToken is ERC20Burnable, Ownable {
    address public minter;

    constructor(
        address initialOwner
    ) ERC20("Gym Loyalty Token", "GLT") Ownable(initialOwner) {}

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// @notice Solo el contrato autorizado (GymControl) puede mintear
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Not authorized to mint");
        _mint(to, amount);
    }

    /// @notice Permitir que otro contrato (GymControl) queme tokens con allowance
    function burnFrom(address account, uint256 amount) public override {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}
