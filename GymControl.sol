// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./GymMembershipNFT.sol";
import "./GymLoyaltyToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

enum MembershipType {
    None, //0
    Monthly, //1
    Quarterly, //2
    SemiAnnual, //3
    Annual //4
}

contract GymControl is Ownable {
    event CheckIn(address indexed user, uint256 timestamp);
    event CheckOut(
        address indexed user,
        uint256 timestamp,
        uint256 duration,
        uint256 rewardTokens
    );
    event WeeklySessionReset(address indexed user, uint256 newStart);
    event UserRegistered(address indexed user, uint256 timestamp);
    event MembershipPurchased(
        address indexed user,
        MembershipType membershipType,
        uint256 startDate,
        uint256 endDate,
        uint8 freeClasses,
        uint256 amountPaid
    );

    // address public owner;

    struct Membership {
        MembershipType membershipType;
        uint256 startDate;
        uint256 endDate;
        uint8 freeClassesRemaining;
    }

    struct User {
        bool registered;
        Membership membership;
        uint256 tokenBalance;
        uint8 attendanceCounter;
        uint256 lastCheckIn;
        uint256 weeklySessionStart; // timestamp del inicio de la semana
        uint8 weeklyCheckIns; // sesiones válidas en la semana actual
    }

    // Costo en tokens por clase adicional, modificable
    uint256 public classTokenCost = 5;

    mapping(address => User) public users;
    // Cantidad de clases gratuitas por tipo de membresía
    mapping(MembershipType => uint8) public defaultFreeClasses;
    // Precios por tipo de membresía
    mapping(MembershipType => uint256) public membershipPrices;
    // tokenURI según el tipo
    mapping(MembershipType => string) public tokenURIs;

    GymMembershipNFT public nftContract;
    GymLoyaltyToken public loyaltyToken;

    constructor(address nftAddress, address tokenAddress) Ownable(msg.sender) {
        // // owner = msg.sender;
        nftContract = GymMembershipNFT(nftAddress);
        loyaltyToken = GymLoyaltyToken(tokenAddress);

        // Inicia los precios de la membresia por tipo
        membershipPrices[MembershipType.None] = 0;
        membershipPrices[MembershipType.Monthly] = 0.05 ether;
        membershipPrices[MembershipType.Quarterly] = 0.12 ether;
        membershipPrices[MembershipType.SemiAnnual] = 0.20 ether;
        membershipPrices[MembershipType.Annual] = 0.35 ether;

        // Inicia las clases gratis por tipo de membresia
        defaultFreeClasses[MembershipType.Monthly] = 1;
        defaultFreeClasses[MembershipType.Quarterly] = 4;
        defaultFreeClasses[MembershipType.SemiAnnual] = 6;
        defaultFreeClasses[MembershipType.Annual] = 12;

        // Establecer los URIs desde IPFS
        tokenURIs[
            MembershipType.Monthly
        ] = "ipfs://bafkreia2olh7ucbcrn42eqy37k22osgkmjmryd3rsaqaia4mizbj7uva7q";
        tokenURIs[
            MembershipType.Quarterly
        ] = "ipfs://bafkreicglygq3tsc5ii5wz34v5mtwjq6br5pgxunrekji5zri3ov62zltq";
        tokenURIs[
            MembershipType.SemiAnnual
        ] = "ipfs://bafkreibp7mazjqbnkpdp4sp66bru3cljfer4pgwspjf4f2sdwgsbhxzcve";
        tokenURIs[
            MembershipType.Annual
        ] = "ipfs://bafkreiccaoezc42za2rxdflha2z6mosfvpueigasz57kexldvtfsnvuauy";
    }

    modifier onlyRegistered() {
        require(users[msg.sender].registered, "Usuario no registrado");
        _;
    }

    function register() external {
        require(!users[msg.sender].registered, "Ya estas registrado");
        users[msg.sender].registered = true;

        emit UserRegistered(msg.sender, block.timestamp);
    }

    // Regresa valor escalado a 2 decimales en ETH (e.g. 0.35 ETH -> 35)
    function getMembershipPriceInEtherUnits(
        MembershipType _type
    ) external view returns (uint256 scaledPrice) {
        uint256 weiPrice = membershipPrices[_type];
        return weiPrice / 1e16;
    }

    function buyMembership(
        MembershipType _type
    ) external payable onlyRegistered {
        require(_type != MembershipType.None, "Tipo de membresia invalido"); //validar diferente membresia por arriba como 5, to do
        require(msg.value >= membershipPrices[_type], "Pago insuficiente");

        uint256 duration;

        if (_type == MembershipType.Monthly) {
            duration = 30 days;
        } else if (_type == MembershipType.Quarterly) {
            duration = 90 days;
        } else if (_type == MembershipType.SemiAnnual) {
            duration = 180 days;
        } else if (_type == MembershipType.Annual) {
            duration = 365 days;
        }

        users[msg.sender].membership = Membership({
            membershipType: _type,
            startDate: block.timestamp,
            endDate: block.timestamp + duration,
            freeClassesRemaining: defaultFreeClasses[_type]
        });

        User storage u = users[msg.sender];

        // Mint NFT con el tokenURI correspondiente
        string memory uri = tokenURIs[_type];
        nftContract.safeMint(msg.sender, uri);

        emit MembershipPurchased(
            msg.sender,
            _type,
            u.membership.startDate,
            u.membership.endDate,
            u.membership.freeClassesRemaining,
            msg.value
        );
    }

    function setTokenURI(
        MembershipType membershipType,
        string memory uri
    ) external onlyOwner {
        tokenURIs[membershipType] = uri;
    }

    // tal vez pueda ser util mas adelante validar si el usuario esta registrado o no
    function isMembershipActiveStrict(address user) public view returns (bool) {
        require(users[user].registered, "User is not registered");
        return users[user].membership.endDate > block.timestamp;
    }

    // si el usuario no esta registrado solo regresa false
    function isMembershipActive(address user) public view returns (bool) {
        if (!users[user].registered) {
            return false;
        }
        return users[user].membership.endDate > block.timestamp;
    }

    function checkIn() external {
        User storage u = users[msg.sender];
        require(u.registered, "Usuario no registrado");
        require(u.membership.endDate > block.timestamp, "Membresia no activa");
        require(
            u.lastCheckIn == 0,
            "Ya hiciste check-in. Debes hacer check-out primero"
        );

        // Reset semanal si aplica
        if (
            u.weeklySessionStart == 0 ||
            block.timestamp > u.weeklySessionStart + 7 days
        ) {
            u.weeklySessionStart = block.timestamp;
            u.weeklyCheckIns = 0;
            emit WeeklySessionReset(msg.sender, u.weeklySessionStart);
        }

        u.lastCheckIn = block.timestamp;

        emit CheckIn(msg.sender, block.timestamp);
    }

    function checkOut() external {
        User storage u = users[msg.sender];
        require(u.registered, "Usuario no registrado");
        require(u.lastCheckIn != 0, "No hiciste check-in");

        uint256 duration = block.timestamp - u.lastCheckIn;
        u.lastCheckIn = 0;

        uint256 reward = 0;

        if (duration >= 1 hours) {
            u.weeklyCheckIns++;
            if (u.weeklyCheckIns <= 4) {
                reward = 5;
            } else {
                reward = 15;
            }

            u.tokenBalance += reward;
            // Mint tokens reales, escalados a 18 decimales
            loyaltyToken.mint(msg.sender, reward * 1e18);

            u.attendanceCounter++;
        }

        emit CheckOut(msg.sender, block.timestamp, duration, reward);
    }

    function enrollClass() external onlyRegistered {
        require(isMembershipActive(msg.sender), "Membresia no activa");

        if (users[msg.sender].membership.freeClassesRemaining > 0) {
            users[msg.sender].membership.freeClassesRemaining--;
        } else {
            require(
                users[msg.sender].tokenBalance >= 5,
                "Tokens insuficientes"
            );
            users[msg.sender].tokenBalance -= 5;

            uint256 cost = classTokenCost * 1e18;
            loyaltyToken.burnFrom(msg.sender, cost); // El usuario debe haber aprobado antes
        }
    }

    // Admin: change prices
    function setMembershipPrice(
        MembershipType _type,
        uint256 _price
    ) external onlyOwner {
        membershipPrices[_type] = _price;
    }

    // Admin: actualizar clases gratuitas por tipo
    function setFreeClasses(
        MembershipType _type,
        uint8 _amount
    ) external onlyOwner {
        require(_type != MembershipType.None, "Tipo invalido");
        defaultFreeClasses[_type] = _amount;
    }

    // Admin: actualizar costo de clase adicional en tokens
    function setClassTokenCost(uint256 _newCost) external onlyOwner {
        classTokenCost = _newCost;
    }

    // Admin: retirar fondos del contrato
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No hay fondos para retirar");
        payable(owner()).transfer(balance);
    }

    // Admin: dar de baja una membresía
    function deactivateMembership(address _user) external onlyOwner {
        require(users[_user].registered, "Usuario no registrado");
        users[_user].membership = Membership({
            membershipType: MembershipType.None,
            startDate: 0,
            endDate: 0,
            freeClassesRemaining: 0
        });
    }

    // Admin: modificar manualmente membresía de un usuario
    function modifyMembership(
        address _user,
        MembershipType _type,
        uint256 _durationDays
    ) external onlyOwner {
        require(users[_user].registered, "Usuario no registrado");
        users[_user].membership = Membership({
            membershipType: _type,
            startDate: block.timestamp,
            endDate: block.timestamp + (_durationDays * 1 days),
            freeClassesRemaining: defaultFreeClasses[_type]
        });
    }

    // Solo el propietario puede llamar a estas funciones
    function getBalanceWei() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function isUserRegistered(address user) external view returns (bool) {
        return users[user].registered;
    }

    function getUserStatus(
        address user
    )
        external
        view
        onlyOwner
        returns (
            bool registered,
            MembershipType membershipType,
            uint256 startDate,
            uint256 endDate,
            uint8 freeClassesRemaining,
            uint256 tokenBalance,
            uint8 attendanceCounter
        )
    {
        User storage u = users[user];
        return (
            u.registered,
            u.membership.membershipType,
            u.membership.startDate,
            u.membership.endDate,
            u.membership.freeClassesRemaining,
            u.tokenBalance,
            u.attendanceCounter
        );
    }
}
